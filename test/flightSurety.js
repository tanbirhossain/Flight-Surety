
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
EtherMultiplayer = 1000000000000000000;

// airline states
var NoState = 0 // not added to the system yet
var AcceptedState = 1
var ActiveState = 2

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeContract(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`1)(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`2)(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`3)(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`4)(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('5)(airline) testing registerAirline() for the first 4 airlines ', async () => {
    /* 
        4 additional ailines witht the owner airline = 5 airlines in total
        which men the last airline will not be accepted 
        until 50% of the active airlines voted for it
    */
    // ARRANGE
    let newAirline2 = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let newAirline5 = accounts[5];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline2, {from: config.owner});
        await config.flightSuretyApp.registerAirline(newAirline3, {from: config.owner});
        await config.flightSuretyApp.registerAirline(newAirline4, {from: config.owner});
    }
    catch(e) {
        console.log(e.message)
    }
    let resultnewAirline2 = await config.flightSuretyData.GetAirlineState.call(newAirline2); 
    let resultnewAirline3 = await config.flightSuretyData.GetAirlineState.call(newAirline3); 
    let resultnewAirline4 = await config.flightSuretyData.GetAirlineState.call(newAirline4); 
    let resultnewAirline5 = await config.flightSuretyData.GetAirlineState.call(newAirline5); 

    // ASSERT
    assert.equal(resultnewAirline2.toNumber(), AcceptedState, "second airlines should be accepted automatically");
    assert.equal(resultnewAirline3.toNumber(), AcceptedState, "3rd airlines should be accepted automatically");
    assert.equal(resultnewAirline4.toNumber(), AcceptedState, "4th airlines should be accepted automatically");
    assert.equal(resultnewAirline5.toNumber(), NoState, "The 5th airline forword should have 50% votes before being accepted");

  });
  
  it('6)(airline) testing ActivateAirline() for the first 4 airlines ', async () => {
      
    // ARRANGE
    let newAirline2 = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let newAirline5 = accounts[5];
    
    // ACT
    try {
        await config.flightSuretyApp.ActivateAirline("A2",{from: newAirline2, value: (10 * EtherMultiplayer)});
        await config.flightSuretyApp.ActivateAirline("A3",{from: newAirline3, value: (10 * EtherMultiplayer)});
        await config.flightSuretyApp.ActivateAirline("A4",{from: newAirline4, value: (10 * EtherMultiplayer)});
        //await config.flightSuretyApp.ActivateAirline({from: newAirline5, value: (10 * EtherMultiplayer)});
    }
    catch(e) {
        console.log(e.message)
    }
    let x = await config.flightSuretyData.GetCredit.call(newAirline5); 
    console.log(x.toNumber())
    let resultnewAirline2 = await config.flightSuretyData.GetAirlineState.call(newAirline2); 
    let resultnewAirline3 = await config.flightSuretyData.GetAirlineState.call(newAirline3); 
    let resultnewAirline4 = await config.flightSuretyData.GetAirlineState.call(newAirline4); 
    let resultnewAirline5 = await config.flightSuretyData.GetAirlineState.call(newAirline5); 

    // ASSERT
    assert.equal(resultnewAirline2.toNumber(), ActiveState, "When Airline2 pay 10 Ether the get activated");
    assert.equal(resultnewAirline3.toNumber(), ActiveState, "When Airline3 pay 10 Ether the get activated");
    assert.equal(resultnewAirline4.toNumber(), ActiveState, "When Airline4 pay 10 Ether the get activated");
    assert.equal(resultnewAirline5.toNumber(), NoState, "The 5th is not accepted yet so it cant be active");
    
  });

  it('7)(airline)(multiparty) testing the voting system for registerAirline() for the 5th airline ', async () => {

  // ARRANGE
  let newAirline2 = accounts[2];
  let newAirline3 = accounts[3];
  let newAirline4 = accounts[4];
  let newAirline5 = accounts[5];

  // ACT
  try {
      await config.flightSuretyApp.registerAirline(newAirline5, {from: newAirline2});
  }
  catch(e) {
      console.log(e.message)
  }

  let resultnewAirline5 = await config.flightSuretyData.GetAirlineState.call(newAirline5); 

  // ASSERT
  assert.equal(resultnewAirline5.toNumber(), AcceptedState, "The 5th airline should be accepted afte getting 2 votes out of 4");

  });

  it('8)(airline)  ActivateAirline() for the 5th airline ', async () => {

    // ARRANGE
    let newAirline2 = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let newAirline5 = accounts[5];
  
    // ACT
    try {
        await config.flightSuretyApp.ActivateAirline("A5",{from: newAirline5, value: 15 * EtherMultiplayer});
    }
    catch(e) {
        console.log(e.message)
    }
    let x = await config.flightSuretyData.GetCredit.call(newAirline5); 
    console.log(x.toNumber())
    let resultnewAirline5 = await config.flightSuretyData.GetAirlineState.call(newAirline5); 
  
    // ASSERT
    assert.equal(resultnewAirline5.toNumber(), ActiveState, "The 5th has credit of 5 ether so it can pay 5 ether to activate");
  
  });
  it('9)(airline)  ActivateAirline() for the 5th airline ', async () => {

    // ARRANGE
    let newAirline2 = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let newAirline5 = accounts[5];
  
    // ACT
    try {
        await config.flightSuretyApp.buyInsurance("F1",{from: config.owner});
    }
    catch(e) {
        console.log(e.message)
    }
    let x = await config.flightSuretyData.GetCredit.call(newAirline5); 
    console.log(x.toNumber())
    //let resultnewAirline5 = await config.flightSuretyData.GetAirlineState.call(newAirline5); 
  
    // ASSERT
    //assert.equal(resultnewAirline5.toNumber(), ActiveState, "The 5th has credit of 5 ether so it can pay 5 ether to activate");
  
    });
  
  });
