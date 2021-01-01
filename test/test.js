const { expect } = require("chai");

describe("Staking", function () {
  let Staking, accounts, provider, MOK;
  beforeEach(async function () {
    // Create contract and account variables
    provider = await ethers.getDefaultProvider();
    accounts = await ethers.getSigners();

    // Deploy Mok token contract
    MOK = await ethers.getContractFactory("MOK");
    mok = await MOK.deploy();

    await mok.deployed();

    // Deploy Lottery contract address
    Staking = await ethers.getContractFactory("Staking");
    staking = await Staking.deploy(accounts[0].address, mok.address);

    await staking.deployed();
  });
  it("Add and Remove Stakeholder", async function () {
    // add stakeholder accounts[0]
    await staking.addStakeHolder(accounts[0].address);
    let numOfStakeHolders = await staking.numOfStakeHolders();
    let stakeholders = [];

    for (i = 0; i < numOfStakeHolders; i++) {
      stakeholders.push(await staking.stakeholders(i));
    }
    console.log(stakeholders.toString());
    expect(stakeholders.toString()).to.equal([accounts[0].address].toString());

    // remove stakeholder and check if array is equal to empty
    await staking.removeStakeHolder(accounts[0].address);

    numOfStakeHolders = await staking.numOfStakeHolders();
    stakeholders = [];

    for (i = 0; i < numOfStakeHolders; i++) {
      stakeholders.push(await staking.stakeholders(i));
    }

    expect(stakeholders.toString()).to.equal('');
  });
  it("Check if address is a Stakeholder", async function() {
    // add accounts[0] as a stakeholder
    await staking.addStakeHolder(accounts[0].address);
    
    console.log((await staking.isStakeHolder(accounts[0].address)).toString());

    // check if each one is a stakeholder recall if is then returns true,index else returns false,0
    expect((await staking.isStakeHolder(accounts[0].address)).toString()).to.equal('true,0');
    expect((await staking.isStakeHolder(accounts[1].address)).toString()).to.equal('false,0');
  });
});
