
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

    var config;
    before('setup contract', async () => {
        config = await Test.Config(accounts);
        await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
    });

    /****************************************************************************************/
    /* Operations and Settings                                                              */
    /****************************************************************************************/

    it(`(multiparty) has correct initial isOperational() value`, async function () {

        // Get operating status
        let status = await config.flightSuretyData.isOperational.call();
        assert.equal(status, true, "Incorrect initial operating status value");

    });

    it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

        // Ensure that access is denied for non-Contract Owner account
        let accessDenied = false;
        try {
            await config.flightSuretyData.setOperatingStatus(false, { from: config.airlines[0] });
        }
        catch (e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, true, "Access not restricted to Contract Owner");

    });

    it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

        // Ensure that access is allowed for Contract Owner account
        let accessDenied = false;
        try {
            await config.flightSuretyData.setOperatingStatus(false, { from: config.owner });
        }
        catch (e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

    });

    it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`,
        async function () {

            await config.flightSuretyData.setOperatingStatus(false);

            let reverted = false;
            try {
                await config.flightSuretyApp.registerAirline(config.airlines[0]);
            }
            catch (e) {
                reverted = true;
            }
            assert.equal(reverted, true, "Access not blocked for requireIsOperational");

            // Set it back for other tests to work
            await config.flightSuretyData.setOperatingStatus(true);

        });

 
    it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {

        // ARRANGE
        let registered = true;
        let funded = true;

        // ACT
        funded = await config.flightSuretyData.airlineFunded.call(config.airlines[0]);

        try {
            await config.flightSuretyApp.registerAirline(config.airlines[0], { from: config.firstAirline });
        }
        catch (e) {
            registered = false;
        }
        //let result = await config.flightSuretyData.isAirline.call(newAirline); 

        // ASSERT
        assert.equal(funded, false,
            "The airline is registered must be funded as well");
        assert.equal(registered, false,
            "Airline has to provide funding in order to be able to register another airline");

    });

    it('(airline) can provide funding', async () => {

        //ARRANGE
        let before = await config.flightSuretyData.airlineFunded.call(config.firstAirline);

        // ACT
        try {
            await config.flightSuretyApp.fundAirline(config.firstAirline,
                { from: config.firstAirline, value: web3.utils.toWei('10', "ether") });
        }
        catch (e) {
        }

        let result = await config.flightSuretyData.airlineFunded.call(config.firstAirline);

        // ASSERT
        assert.equal(before, false, "The airline must be funded");
        assert.equal(result, true, "Airline is able to provide funding");

    });

    it('(airline) can be registered using registerAirline() if fundings have been provided', async () => {


        // ACT
        try {
            await config.flightSuretyApp.registerAirline(config.airlines[0], { from: config.firstAirline });
        }
        catch (e) {
            console.log(e);
        }
        let result = await config.flightSuretyData.airlineRegistered.call(config.airlines[0]);
        let counter = await config.flightSuretyData.getRegisteredAirlinesCount();

        // ASSERT
        assert.equal(result, true,
            "Airline can be registered using registerAirline() funding have been provided");
        assert.equal(counter, 2,
            "Registered airlines: firstAirline,new airline");

    });

    // REQ: Only existing airline may register a new airline 
    // until there are at least four airlines registered
    // Demonstrated either with Truffle test or by making call from client Dapp
    it('(airline) Only existing airline can register new airline using registerAirline() until there are at leat four airlines registered and it is funded', async () => {

            // ARRANGE

            // ACT
            try {
                await config.flightSuretyApp.registerAirline(config.airlines[1], { from: config.firstAirline });
                await config.flightSuretyApp.registerAirline(config.airlines[2], { from: config.firstAirline });
            }
            catch (e) {
                console.log(e);
            }
            let before = await config.flightSuretyData.getRegisteredAirlinesCount();
            assert.equal(before, 4, ' 4 of registered airlines');
            try {
                await config.flightSuretyApp.registerAirline(config.airlines[3], { from: config.firstAirline });
                await config.flightSuretyApp.registerAirline(config.airlines[4], { from: config.firstAirline });
                await config.flightSuretyApp.registerAirline(config.airlines[5], { from: config.firstAirline });
            }
            catch (e) {
                console.log(e);
            }

            let after = await config.flightSuretyData.getRegisteredAirlinesCount();
            let exist = await config.flightSuretyData.getExistAirlinesCount();
            assert.equal(after, 4, ' 4 of registered airlines when without consensus');
            assert.equal(exist, 7, ' 7 of existing airlines when without consensus');
        });

  

    it('(airline) 5th airline multy party consensus', async () => {

        // ARRANGE
        let newAirline = config.airlines[3];

        // ACT
        try {
            await config.flightSuretyApp.fundAirline(config.airlines[0], 
                            { from: config.airlines[0], value: web3.utils.toWei('10', "ether") });
            await config.flightSuretyApp.fundAirline(config.airlines[1], 
                            { from: config.airlines[1], value: web3.utils.toWei('10', "ether") });
            await config.flightSuretyApp.fundAirline(config.airlines[2], 
                            { from: config.airlines[2], value: web3.utils.toWei('10', "ether") });
        }
        catch (e) {
            console.log(e)
        }

        let funded = await config.flightSuretyData.getFundedAirlinesCount();
        assert.equal(funded, 4, ' 4 funded airlines, first airline included');

        try {
            await config.flightSuretyApp.voteForAirline(newAirline, { from: config.firstAirline });
            await config.flightSuretyApp.voteForAirline(newAirline, { from: config.airlines[0] });
            await config.flightSuretyApp.voteForAirline(newAirline, { from: config.airlines[1] });
          
        }
        catch (e) {
            console.log(e)
        }

        let registered = await config.flightSuretyData.airlineRegistered(newAirline);
        // ASSERT
        assert.equal(registered, true, "if needed number reach airline will be registered");

    });

    it(`(passenger) can buy insurance`, async () => {
        await Test.passesWithEvent(
            'InsurancePurchased',
            config.flightSuretyData.buyInsurance(
                config.passengers[0],
                config.firstAirline,
                "AB123",
                12341234,
                { from: config.passengers[0], value: web3.utils.toWei('0.1', 'ether') })
        );

        let insurance = await config.flightSuretyApp.getInsurance.call(
            config.passengers[0],
            config.firstAirline,
            "AB123",
            12341234,
            { from: config.passengers[0] }
        );
        let value = web3.utils.fromWei(insurance.value, 'ether').toString();
        assert.equal(insurance.state, "2", "not insurance purchased state")
        assert.equal(value, "0.1", "value of insurance must match contract specifications");
    });

});
