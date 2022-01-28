let CakeToken = artifacts.require("./CakeToken.sol");
let SyrupBar = artifacts.require("./SyrupBar.sol");
let MasterChef = artifacts.require("./MasterChef.sol")

module.exports = async function (deployer, network, accounts) {

    // await deployer.deploy(CakeToken);
    // const CakeTokenAddr = await CakeToken.deployed();
    // console.log("CakeToken: ", CakeTokenAddr.address);

    // await deployer.deploy(SyrupBar, CakeTokenAddr.address);
    // const SyrupBarAddr = await SyrupBar.deployed();
    // console.log("SyrupBar: ", SyrupBarAddr.address);
    CakeTokenAddr = "0x8B6571C6D26dBa39be2263C35E3006A18312B328";
    SyrupBarAddr = "0x3A20f2e7D4c4bb4A6A7053d51bC317f6046cd02a";


    const cakePerBlock=40*1E18;
    const startBlock=703820;
    const devAddr="0x9892657D3A386661AF2fA989AE10b6916d43b93F";
    await deployer.deploy(MasterChef, CakeTokenAddr, SyrupBarAddr, devAddr, BigInt(cakePerBlock), startBlock);
    const MasterChefAddr = await MasterChef.deployed().address;
    console.log("MasterChef: ", MasterChefAddr);

};