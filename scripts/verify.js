const fs = require("fs");

const exec = require("child_process").exec;

const runComman = (command) => {
  return new Promise((resolve, reject) => {
    exec(command, function (error, stdout, stderr) {
      console.log("stdout: " + stdout);
      resolve(stdout);
      if (stderr) {
        console.log("stderr: " + stderr);
        reject(stderr);
      }
      if (error !== null) {
        console.log("exec error: " + error);
        reject(error);
      }
    });
  });
};

async function main() {
  const config = require("../config.json");
  for (let i = 0; i < Object.values(config).length; i++) {
    const contract = Object.values(config)[i];
    const inputStr = contract?.input ? contract.input.join(" ") : "";
    console.log(
      "Start verifying contract: " + contract.contractName,
      contract.address
    );
    await runComman(
      `hardhat verify --contract contracts/${contract.contractName}.sol:${contract.contractName}  --network polygon ${contract.address} ${inputStr}`
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
