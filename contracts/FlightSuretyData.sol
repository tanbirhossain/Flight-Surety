pragma solidity ^ 0.4 .24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath
    for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    mapping(address => uint256) private authorizedAddresses;
    bool private operational = true; // Blocks all state changes throughout the contract if false

    struct AirlineStruct {
        uint256 State;
        string Name;
        address Address;
    }
    mapping(address => AirlineStruct) private Airlines;
    mapping(address => uint256) private Credit;
    mapping(address => uint256) private InsuranceCredit;
    mapping(address => uint256) private AirlineCredit;
    uint256 AirlineCount = 0;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor
        ()
    public {
        contractOwner = msg.sender;
        authorizedAddresses[contractOwner] = 1;
        AirlineStruct memory NewAirline;
        NewAirline.Address = msg.sender;
        NewAirline.Name = "A1";
        NewAirline.State = 2;
        Airlines[msg.sender] = NewAirline;
        AirlineCount.add(1);
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
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }


    modifier requireIsCallerAuthorized() {
        require(authorizedAddresses[msg.sender] == 1, "Caller is not contract owner");
        _;
    }
    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational()
    public
    view
    returns(bool) {
        return operational;
    }


    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(
        bool mode
    )
    external
    requireContractOwner {
        operational = mode;
    }

    function authorizeContract(address contractAddress)
    external
    requireContractOwner {
        authorizedAddresses[contractAddress] = 1;
    }

    function deauthorizeContract(address contractAddress)
    external
    requireContractOwner {
        delete authorizedAddresses[contractAddress];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline(address _NewAirlineAddress)
    external {
        AirlineStruct memory NewAirline;
        NewAirline.Address = _NewAirlineAddress;
        NewAirline.State = 1;
        Airlines[_NewAirlineAddress] = NewAirline;
        AirlineCount.add(1);

    }

    function ChangeAirlineState(address _AirlineAddress, uint256 state) external 
    {
        Airlines[_AirlineAddress].State = state;
    }
    function ChangeAirlineName(address _AirlineAddress, string _Name) external 
    {
        Airlines[_AirlineAddress].Name = _Name;
    }

    function AddCredit(address _Address, uint256 value) external 
    {
        uint256 newCredit = value.add(Credit[_Address]);
        Credit[_Address] = newCredit;
    }
    function SubCredit(address _Address, uint256 value) external 
    {
        Credit[_Address] = Credit[_Address].sub(value);
    }
    function GetCredit(address _Address) view external 
    returns(uint256 value)
    {
        value = Credit[_Address];
        return value;
    }

    function GetAirlineState(address AirlineAddress) view external
    returns(uint256 State) 
    {

        State = Airlines[AirlineAddress].State;
        return State;
    }
    function GetAirlineCount() view external
    returns(uint256 count) {

        count = AirlineCount;
        return count;
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy()
    external
    payable {

    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees()
    external
    pure {}


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay()
    external
    pure {}

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund()
    public
    payable {}

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    )
    pure
    internal
    returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    function ()
    external
    payable {
        fund();
    }


}