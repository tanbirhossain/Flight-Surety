import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';
import 'babel-polyfill';


let accounts;
let RegistrationFee = 0;
let OracleArray = [];
let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

CreatOracles(20);

async function CreatOracles(num) {
  accounts = await web3.eth.getAccounts();
  RegistrationFee = await flightSuretyApp.methods.REGISTRATION_FEE().call({
    from: accounts[0]
  })
  let OracleAccount
  for (let i = 0; i < num; i++) {
    OracleAccount = accounts[i];
    await registerOracle(OracleAccount);
  }

  //console.log(OracleArray);
}

async function registerOracle(OracleAccount) {
  var registerOracle = await flightSuretyApp.methods.registerOracle().send({
    from: OracleAccount,
    value: RegistrationFee,
    gas: 3000000
  })
  console.log(`New Oracle Added: ${OracleAccount}`);


  let ResultIndexes = await flightSuretyApp.methods.getMyIndexes().call({
    from: OracleAccount
  });
  console.log(`New Oracle Inexes: [${ResultIndexes[0]}, ${ResultIndexes[1]}, ${ResultIndexes[2]}]`);
  OracleArray.push([OracleAccount, ResultIndexes]);
}

function getRandomeStatus() {
  return (Math.floor(Math.random() * Math.floor(5)) * 10);
}

async function submitOracleResponse(index, airline, flight, timestamp, FlightStatusCode, OracleAddress) {
  try{
    await flightSuretyApp.methods.submitOracleResponse(index, airline, flight, timestamp, FlightStatusCode)
    .send({
      from: OracleAddress,
      gas: 3000000
    });

  }
  catch(e)
  {
    console.log(e.message)
  }

}




flightSuretyApp.events.OracleRequest({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error);
  
  //console.log(`Oracle Count = ${OracleArray.length}`);
  console.log(event.returnValues);
  let index = event.returnValues.index;
  let airline = event.returnValues.airline;
  let flight = event.returnValues.flight;
  let timestamp = event.returnValues.timestamp;

  var FlightStatusCode = getRandomeStatus();
  console.log("random statusCode", FlightStatusCode)

  for (let i = 0; i < OracleArray.length; i++) {
    if (OracleArray[i][1].includes(index)) {
      console.log(`Oracle With Matched Index Found`);
      submitOracleResponse(index, airline, flight, timestamp, FlightStatusCode, OracleArray[i][0])
    }
  }
  
});

const app = express();
app.get('/api', (req, res) => {
  res.send({
    message: 'An API for use with your Dapp!'
  })
})

export default app;