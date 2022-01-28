let CakeToken = artifacts.require("./CakeToken.sol");
let SyrupBar = artifacts.require("./SyrupBar.sol");
let MasterChef = artifacts.require("./MasterChef.sol")

module.exports = async function (deployer, network, accounts) {

    await deployer.deploy(CakeToken);
    const CakeTokenAddr = await CakeToken.deployed();
    console.log("CakeToken: ", CakeTokenAddr.address);

    await deployer.deploy(SyrupBar, CakeTokenAddr.address);
    const SyrupBarAddr = await SyrupBar.deployed();
    console.log("SyrupBar: ", SyrupBarAddr.address);

    const cakePerBlock=40;
    const startBlock=703820;
    const devAddr="0x9892657D3A386661AF2fA989AE10b6916d43b93F";
    await deployer.deploy(MasterChef, CakeTokenAddr.address, SyrupBarAddr.address, devAddr, cakePerBlock, startBlock);
    const MasterChefAddr = await MasterChef.deployed();
    console.log("MasterChef: ", MasterChefAddr.address);

};