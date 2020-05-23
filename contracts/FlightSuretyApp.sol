pragma solidity ^ 0.4.24;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath
    for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // data contract
    FlightSuretyData DataContract;

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
        address[] insuredAddresses;
        mapping(address => uint256) payment;
    }
    mapping(string => Flight) private flights;

    mapping(address => address[]) private airlineAcceptance;

    //enum 
    enum State {
        Null, // 0
        Accepted, // 1
        Active // 2        
    }


    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in 
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        // Modify to call data contract's status
        require(true, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }
    modifier requireActiveAirline(address _airline) {
        require(DataContract.GetAirlineState(_airline) == uint256(State.Active), "airline not active");
        _;
    }
    modifier requireAcceptedAirline(address _airline) {
        require(DataContract.GetAirlineState(_airline) == uint256(State.Accepted), "airline not accepted yet");
        _;
    }

    modifier requireNotAcceptedAirline(address _airline) {
        require(DataContract.GetAirlineState(_airline) != uint256(State.Accepted), "airline already accepted");
        _;
    }
    modifier requireValidflight(string FlightCode){
        require(flights[FlightCode].statusCode == STATUS_CODE_ON_TIME, "This flight is no longer valid for Insurance");
        _;
    }


    modifier paidEnough(uint _price) {
        require(msg.value >= _price, "Not Paid Enough");
        _;
    }
    modifier requireLimitedPayment(uint _Max) {
        require(msg.value <= _Max, "payment exceed maximum");
        _;
    }
    modifier requireNoDuplicatedInsurance(string FlightCode) {
        require(flights[FlightCode].payment[msg.sender] == 0, "user is already insured");
        _;
    }


    /********************************************************************************************/
    /*                                        EVENTS                                            */
    /********************************************************************************************/

    event AirlineVoteChange(address NewAirline, address VoterAirline, uint256 TotalVotes);
    event AirlineAccepted(address NewAirline);
    event AirlineIsActivated(address Airline, string Name);
    event NewFlightRegistration(string FlightCode);
    event FlightInsuranceBought(string FlightCode, address buyer, uint256 payment);
    event FlightStatusChange(string flightCode, uint8 statusCode);
    event InsuranceCreditAdded(address passenger,uint256 credit,string flightCode);
    event CreditWithdrawn(address passenger, uint256 amountToRefund);




    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
     * @dev Contract constructor
     *
     */
    constructor(address dataContractAddress) public 
    {
        contractOwner = msg.sender;
        DataContract = FlightSuretyData(dataContractAddress);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view
    returns(bool) {
        return operational; // Modify to call data contract's status
    }
    function setOperatingStatus(bool mode) external
    requireContractOwner {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/


    /**
     * @dev Add an airline to the registration queue
     *
     */
    function registerAirline(address _NewAirline) external
    requireIsOperational()
    requireActiveAirline(msg.sender)
    requireNotAcceptedAirline(_NewAirline) 
    {
        bool isDuplicate = false;
        for (uint c = 0; c < airlineAcceptance[_NewAirline].length; c++) {
            if (airlineAcceptance[_NewAirline][c] == msg.sender) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "Np Duplicated votes allowed.");

        airlineAcceptance[_NewAirline].push(msg.sender);

        emit AirlineVoteChange(_NewAirline, msg.sender, airlineAcceptance[_NewAirline].length);

        uint256 AirlineCount = DataContract.GetAirlineCount();
        if (AirlineCount < 5 || airlineAcceptance[_NewAirline].length >= (AirlineCount.div(2))) {
            DataContract.registerAirline(_NewAirline);
            emit AirlineAccepted(_NewAirline);
        }

    }

    function ActivateAirline(string _Name) payable external
    requireIsOperational()
    paidEnough(10 ether)
    requireAcceptedAirline(msg.sender) {
        
        DataContract.ChangeAirlineState(msg.sender, uint256(State.Active));
        DataContract.ChangeAirlineName(msg.sender, _Name);
        uint256 remains = uint256(msg.value).sub(10 ether);
        DataContract.AddCredit(msg.sender ,remains);
        //DataContract.SubCredit(msg.sender, 10 ether);

        emit AirlineIsActivated(msg.sender, _Name);

    }


    /**
     * @dev Register a future flight for insuring.
     *
     */
    function registerFlight(string FlightCode, uint256 time)
    requireActiveAirline(msg.sender)
    external
    {
        Flight memory NewFlight;
        NewFlight.isRegistered = true;
        NewFlight.statusCode = STATUS_CODE_ON_TIME;
        NewFlight.updatedTimestamp = time;
        NewFlight.airline = msg.sender;

        flights[FlightCode] = NewFlight;

        emit NewFlightRegistration(FlightCode);


    }
    function getFlight(string _FlightCode)
    view
    external
    returns(
     uint8 statusCode,
     address airline,
     uint256 Timestamp
     )
    {
        statusCode = flights[_FlightCode].statusCode;
        airline = flights[_FlightCode].airline;
        Timestamp = flights[_FlightCode].updatedTimestamp;
        return(
            statusCode,
            airline,
            Timestamp
        );

    }

    /**
     * @dev Buy Flight Insurance.
     *
     */
    function buyInsurance(string FlightCode)
    requireNoDuplicatedInsurance(FlightCode) 
    requireValidflight(FlightCode)
    requireLimitedPayment(1 ether)
    payable
    external
    {
        flights[FlightCode].insuredAddresses.push(msg.sender);
        flights[FlightCode].payment[msg.sender] = msg.value;
        emit FlightInsuranceBought(FlightCode, msg.sender, msg.value);


    }

    /**
     * @dev withdraw credit.
     *
     */
    function withdrawCredit()
    external
    {
        require(DataContract.GetCredit(msg.sender) > 0, "No Credit Found For This Account");
        uint256 amountToRefund = DataContract.GetCredit(msg.sender);
        DataContract.SubCredit(msg.sender, amountToRefund);
        msg.sender.transfer(amountToRefund);

        emit CreditWithdrawn(msg.sender, amountToRefund);


    }

    /**
     * @dev Get credit.
     *
     */
    function getCredit()
    view
    external
    returns(uint256 value)
    {        
        return DataContract.GetCredit(msg.sender);
    }

    /**
     * @dev Called after oracle has updated flight status
     *
     */
    function processFlightStatus(
        string memory flightCode,
        uint8 statusCode
    )
    internal
    {
        require(flights[flightCode].statusCode != statusCode);

        flights[flightCode].statusCode = statusCode;
        emit FlightStatusChange(flightCode, statusCode);
        
        if(statusCode == STATUS_CODE_LATE_AIRLINE)
        {
            for(uint i=0; i < flights[flightCode].insuredAddresses.length; i++)
            {
                address passenger = flights[flightCode].insuredAddresses[i];
                uint256 payment = flights[flightCode].payment[passenger];
                uint256 credit = payment.add(payment.div(2));
                DataContract.AddCredit(flights[flightCode].insuredAddresses[i],credit);
                emit InsuranceCreditAdded(passenger, credit, flightCode);
            }
            // reset the insured addreses after alocating credits
            flights[flightCode].insuredAddresses = new address[](0);
        }


    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(
        address airline,
        string flight,
        uint256 timestamp
    )
    external {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
            requester: msg.sender,
            isOpen: true
        });

        emit OracleRequest(index, airline, flight, timestamp);
    }




// region ORACLE MANAGEMENT


    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 5;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester; // Account that requested status
        bool isOpen; // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses; // Mapping key is the status code reported
        // This lets us group responses and identify
        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle()
    external
    payable {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
            isRegistered: true,
            indexes: indexes
        });
    }

    function getMyIndexes()
    view
    external
    returns(uint8[3]) {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp,
        uint8 statusCode
    )
    external {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(flight, statusCode);
        }
    }


    function getFlightKey(
        address airline,
        string flight,
        uint256 timestamp
    )
    pure
    internal
    returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(
        address account
    )
    internal
    returns(uint8[3]) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(
        address account
    )
    internal
    returns(uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0; // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    // endregion

}

// region Data Interface
contract FlightSuretyData {
    // interface function
    function registerAirline(address _NewAirlineAddress) external {}
    function ChangeAirlineState(address _AirlineAddress, uint256 state) external {}
    function ChangeAirlineName(address _AirlineAddress, string _Name) external {}
    function AddCredit(address _Address, uint256 value) external {}
    function SubCredit(address _Address, uint256 value) external {}

    function GetCredit(address _Address) view external returns(uint256 value){}
    function GetAirlineState(address AirlineAddress) view external returns(uint256 State) {}
    function GetAirlineCount() view external returns(uint256 count) {}




}


// endregion