
let MasterChef = artifacts.require("./MasterChef.sol")

module.exports = async function (deployer, network, accounts) {

   
    PeaceTokenAddr = "0x9CA00f0B5562914bcD84Ca6e0132CaE295cc84B7";
    
    const devAddr="0xd9C057BF4A2FEAC8264f33aBbCecAA233A2f823c";
    const rewardAddr="0xbAB8E9cA493E21d5A3f3e84877Ba514c405be0e1";

    await deployer.deploy(MasterChef, PeaceTokenAddr, devAddr, rewardAddr);
    const MasterChefAddr = await MasterChef.deployed();
    console.log("MasterChef: ", MasterChefAddr.address);

};