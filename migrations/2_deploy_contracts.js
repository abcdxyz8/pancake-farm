// let CakeToken = artifacts.require("./CakeToken.sol");
let SyrupBar = artifacts.require("./SyrupBar.sol");
let MasterChef = artifacts.require("./MasterChef.sol")

module.exports = async function (deployer, network, accounts) {

    // await deployer.deploy(CakeToken);
    // const CakeTokenAddr = await CakeToken.deployed();
    // console.log("CakeToken: ", CakeTokenAddr.address);
    PeaceTokenAddr = "0x9CA00f0B5562914bcD84Ca6e0132CaE295cc84B7";

    await deployer.deploy(SyrupBar, PeaceTokenAddr);
    const SyrupBarAddr = await SyrupBar.deployed();
    console.log("SyrupBar: ", SyrupBarAddr.address);

    // SyrupBarAddr = "0x3A20f2e7D4c4bb4A6A7053d51bC317f6046cd02a";


    const peacePerBlock=40*1E18;
    const startBlock=703820;
    const devAddr="0x9892657D3A386661AF2fA989AE10b6916d43b93F";
    await deployer.deploy(MasterChef, PeaceTokenAddr, SyrupBarAddr.address, devAddr, BigInt(peacePerBlock), startBlock);
    const MasterChefAddr = await MasterChef.deployed();
    console.log("MasterChef: ", MasterChefAddr.address);

};