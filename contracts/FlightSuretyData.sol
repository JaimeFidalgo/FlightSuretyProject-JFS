pragma solidity ^0.5.0;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false

    mapping(address => bool) public authorizedCallers;

    struct Airline {
        bool exists;
        bool registered;
        bool funded;
        bytes32[] flightKeys;
        Votes votes;
        uint256 numbInsurance;
    }
    mapping(address => Airline) private airlines;
    uint256 private airlinesCounter = 0;
    uint256 private registeredAirlinesCounter = 0;
    uint256 private fundedAirlinesCounter = 0;
    struct Votes{
        uint votersCounter;
        mapping(address => bool) voters;
    }


    struct Insurance {
        address buyer;
        uint256 value;
        address airline;
        string flightName;
        uint256 departure;
        InsuranceState state;
    }

    enum InsuranceState {
        NotExistent,
        Waiting,
        Purchased,
        Passed,
        Expired
    }

    struct FlightInsurance {
        mapping(address => Insurance) insurances;
        address[] keys;
    }
    mapping(bytes32 => FlightInsurance) private flightInsurances;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event AuthorizeCaller(address caller);

    event AirlineExist(address airline, bool exist);
    event AirlineRegistered(address airline, bool exist, bool registered);
    event AirlineFunded(
        address airlineAddr,
        bool exist,
        bool registered,
        bool funded,
        uint256 fundedCount
    );
    event InsurancePurchased(bytes32 flightKey);

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    //Must register first airline at deployment time
    constructor(address airlineAddr) public {
        contractOwner = msg.sender;

        airlines[airlineAddr] = Airline({
            exists: true,
            registered: true,
            funded: false,
            flightKeys: new bytes32[](0),
            votes: Votes(0),
            numbInsurance: 0
        });

        airlinesCounter = airlinesCounter.add(1);
        registeredAirlinesCounter = registeredAirlinesCounter.add(1);
        emit AirlineExist(airlineAddr, airlines[airlineAddr].exists);
        emit AirlineRegistered(
            airlineAddr,
            airlines[airlineAddr].exists,
            airlines[airlineAddr].registered
        );
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

    modifier requireAuthorizedCaller(address contractAddress) {
        require(
            authorizedCallers[contractAddress] == true,
            "Caller must be authorized"
        );
        _;
    }

    modifier requireAirLineExist(address airlineAddr) {
        require(airlines[airlineAddr].exists, "Airline must exist");
        _;
    }

    modifier requireAirLineRegistered(address airlineAddr) {
        require(airlines[airlineAddr].exists, "Airline must exist");
        require(
            airlines[airlineAddr].registered,
            "Airline must be registered"
        );
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    function authorizeCaller(address contractAddress)
        public
        requireContractOwner
        requireIsOperational
    {
        require(
            authorizedCallers[contractAddress] == false,
            "It is authorized already"
        );
        authorizedCallers[contractAddress] = true;
        emit AuthorizeCaller(contractAddress);
    }

    function callerAuthorized(address contractAddress)
        public
        view
        returns (bool)
    {
        return authorizedCallers[contractAddress];
    }

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    function getExistAirlinesCount() public view returns (uint256) {
        return airlinesCounter;
    }

    function getRegisteredAirlinesCount() public view returns (uint256) {
        return registeredAirlinesCounter;
    }

    function getFundedAirlinesCount() public view returns (uint256) {
        return fundedAirlinesCounter;
    }

    function getAirlineVotesCount(address airlineAddr)
        public
        view
        returns (uint256)
    {
        return airlines[airlineAddr].votes.votersCounter;
    }

    function airlineExists(address airlineAddr) public view returns (bool) {
        return airlines[airlineAddr].exists;
    }

    function airlineRegistered(address airlineAddr)
        public
        view
        returns (bool)
    {
        if (airlines[airlineAddr].exists) {
            return airlines[airlineAddr].registered;
        }
        return false;
    }

    function airlineFunded(address airlineAddr) public view returns (bool) {
        return airlines[airlineAddr].funded;
    }

    function getInsurance(
        address buyer,
        address airlineAddr,
        string memory flightName,
        uint256 departure
    ) public view returns (uint256 value, InsuranceState state) {
        bytes32 flightKey = getFlightKey(airlineAddr, flightName, departure);
        FlightInsurance storage flightInsurance = flightInsurances[flightKey];
        Insurance storage insurance = flightInsurance.insurances[buyer];
        return (insurance.value, insurance.state);
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline(address airlineAddr, bool registered)
        public
        requireIsOperational
    {
        airlines[airlineAddr] = Airline({
            exists: true,
            registered: registered,
            funded: false,
            flightKeys: new bytes32[](0),
            votes: Votes(0),
            numbInsurance: 0
        });

        airlinesCounter = airlinesCounter.add(1);
        if (registered == true) {
            registeredAirlinesCounter = registeredAirlinesCounter.add(1);
            emit AirlineRegistered(
                airlineAddr,
                airlines[airlineAddr].exists,
                airlines[airlineAddr].registered
            );
        } else
            emit AirlineExist(airlineAddr, airlines[airlineAddr].exists);
    }

    function setAirlineRegistered(address airlineAddr)
        public
        requireIsOperational
        requireAirLineExist(airlineAddr)
    {
        require(
            airlines[airlineAddr].registered == false,
            "Airline is already registered"
        );
        airlines[airlineAddr].registered = true;
        registeredAirlinesCounter = registeredAirlinesCounter.add(1);
        emit AirlineRegistered(
            airlineAddr,
            airlines[airlineAddr].exists,
            airlines[airlineAddr].registered
        );
    }

    function getMinimumRequiredVotingCount() public view returns (uint256) {
        return registeredAirlinesCounter.div(2);
    }

    function voteForAirline(
        address votingAirlineAddress,
        address airlineAddr
    ) public requireIsOperational {
        require(
            airlines[airlineAddr].votes.voters[votingAirlineAddress] ==
                false,
            "Airline already voted"
        );

        airlines[airlineAddr].votes.voters[votingAirlineAddress] = true;
        uint256 startingVotes = getAirlineVotesCount(airlineAddr);

        airlines[airlineAddr].votes.votersCounter = startingVotes.add(1);}
       

    function registerFlightKey(address airlineAddr, bytes32 flightKey)
        public
        requireAuthorizedCaller(msg.sender)
    {
        airlines[airlineAddr].flightKeys.push(flightKey);
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buyInsurance(
        address buyer,
        address airlineAddr,
        string memory flightName,
        uint256 departure
    ) public payable {
        bytes32 flightKey = getFlightKey(airlineAddr, flightName, departure);
        FlightInsurance storage flightInsurance = flightInsurances[flightKey];
        flightInsurance.insurances[buyer] = Insurance({
            buyer: buyer,
            value: msg.value,
            airline: airlineAddr,
            flightName: flightName,
            departure: departure,
            state: InsuranceState.Purchased
        });
        flightInsurance.keys.push(buyer);
        emit InsurancePurchased(flightKey);
    }

   
    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees(bytes32 flightKey, uint8 credit)
        public
        requireAuthorizedCaller(msg.sender)
    {
        FlightInsurance storage flightInsurance = flightInsurances[flightKey];

        for (uint256 i = 0; i < flightInsurance.keys.length; i++) {
            Insurance storage insurance = flightInsurance.insurances[
                flightInsurance.keys[i]
            ];

            if (insurance.state == InsuranceState.Purchased) {
                insurance.value = insurance.value.mul(credit).div(100);
                if (insurance.value > 0)
                    insurance.state = InsuranceState.Passed;
                else insurance.state = InsuranceState.Expired;
            } else {
                insurance.state = InsuranceState.Expired;
            }
        }
    }

   
    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay(bytes32 flightKey) external payable {
        FlightInsurance storage flightInsurance = flightInsurances[flightKey];
        Insurance storage insurance = flightInsurance.insurances[msg.sender];

        require(
            insurance.state == InsuranceState.Passed,
            "Not valid insurance"
        );
        require(address(this).balance > insurance.value, "error");

        uint256 value = insurance.value;
        insurance.value = 0;
        insurance.state = InsuranceState.Expired;
        address payable insuree = address(uint160(insurance.buyer));
        insuree.transfer(value);
    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund(address airlineAddr)
        public
        payable
        requireIsOperational
        requireAirLineRegistered(airlineAddr)
    {
        airlines[airlineAddr].funded = true;
        fundedAirlinesCounter = fundedAirlinesCounter.add(1);
        emit AirlineFunded(
            airlineAddr,
            airlines[airlineAddr].exists,
            airlines[airlineAddr].registered,
            airlines[airlineAddr].funded,
            fundedAirlinesCounter
        );
    }

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    function() external payable {
        fund(msg.sender);
    }
}
