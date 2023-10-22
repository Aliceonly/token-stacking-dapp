loadInitialData("sevenDays");

connectMe("metamask_wallet");

function connectWallet() {}

function openTab(event, name) {
  console.log(name);
  contractCall = name;
  getSelectedTab(name);
  loadInitialData(name);
}

async function loadInitialData(sClass) {
  console.log(sClass);
  try {
    clearInterval(countDownGlobal);

    let cObj = new web3Main.eth.Contract(
      SELECT_CONTRACT[_NETWORK_ID].STAKING.abi,
      SELECT_CONTRACT[_NETWORK_ID].STAKING[sClass].address
    );

    let totalUsers = await cObj.methods.getTotalUsers().call();
    let cApy = await cObj.methods.getAPY().call();

    let userDetail = await cObj.methods.getUser(currentAddress).call();

    const user = {
      lastRewardCalculationTime: userDetail.lastRewardCalculationTime,
      lastStakingTime: userDetail.lastStakingTime,
      rewardAmount: userDetail.rewardAmount,
      rewardsClaimedSoFar: userDetail.rewardsClaimedSoFar,
      stakeAmount: userDetail.stakeAmount,
      address: currentAddress,
    };
    localStorage.setItem("User", JSON.stringify(user));

    let userDetailBal = userDetail.stakeAmount / 10 ** 18;

    document.getElementById(
      "total-locked-user-token"
    ).innerHTML = `${userDetailBal}`;

    document.getElementById(
      "num-of-stackers-value"
    ).innerHTML = `${totalUsers}`;
    document.getElementById("apy-value-feature").innerHTML = `${cApy}%`;

    let totalLockedTokens = await cObj.methods.getTotalStakedTokens().call();
    let earlyUnstakeFee = await cObj.methods
      .getEarlyUnstakeFeePercentage()
      .call();

    document.getElementById("total-locked-tokens-value").innerHTML = `${
      totalLockedTokens / 10 ** 18
    } ${SELECT_CONTRACT[_NETWORK_ID].TOKEN.symbol}`;

    document
      .querySelectorAll(".early-unstake-fee-value")
      .forEach(function (element) {
        element.innerHTML = `${earlyUnstakeFee / 100} %`;
      });

    let minStakeAmount = await cObj.methods.getMinimunStakingAmount().call();
    minStakeAmount = Number(minStakeAmount);
    let minA;

    if (minStakeAmount) {
      minA = `${(minStakeAmount / 10 ** 18).toLocaleString()} ${
        SELECT_CONTRACT[_NETWORK_ID].TOKEN.symbol
      }`;
    } else {
      minA = "N/A";
    }

    document
      .querySelectorAll(".Minimun-Staking-Amount")
      .forEach(function (element) {
        element.innerHTML = `${minA}`;
      });
    document
      .querySelectorAll(".Maximun-Staking-Amount")
      .forEach(function (element) {
        element.innerHTML = `${(10000000).toLocaleString()} ${
          SELECT_CONTRACT[_NETWORK_ID].TOKEN.symbol
        }`;
      });

    let isStakingPause = await cObj.methods.getStakingStatus().call();
    let isStakingPauseText;

    let startDate = await cObj.methods.getStakeStartDate().call();
    startDate = Number(startDate) * 1000;

    let endDate = await cObj.methods.getStakeEndDate().call();
    endDate = Number(endDate) * 1000;

    let stakeDays = await cObj.methods.getStakeDays().call();

    let days = Math.floor(Number(stakeDays) / (3600 * 24));

    let dayDisplay = days > 0 ? days + (days == 1 ? "day, " : "days, ") : "";

    document.querySelectorAll(".Lock-period-value").forEach(function (element) {
      element.innerHTML = `${dayDisplay}`;
    });

    let rewardBal = await cObj.methods
      .getUserEstimatedRewards()
      .call({ from: currentAddress });

    document.getElementById("user-reward-balance-value").value = `Reward: ${
      rewardBal / 10 ** 18
    } ${SELECT_CONTRACT[_NETWORK_ID].TOKEN.symbol}`;

    let balMainUser = currentAddress
      ? await oContractToken.methods.balanceOf(currentAddress).call()
      : "";

    balMainUser = Number(balMainUser) / 10 ** 18;

    document.getElementById(
      "user-token-balance"
    ).innerHTML = `Balance: ${balMainUser}`;

    let currentDate = new Date().getTime();

    if (isStakingPause) {
      isStakingPauseText = "Paused";
    } else if (currentDate < startDate) {
      isStakingPauseText = "Locked";
    } else if (currentDate > endDate) {
      isStakingPauseText = "Ended";
    } else {
      isStakingPauseText = "Active";
    }

    document
      .querySelectorAll(".active-status-stacking")
      .forEach(function (element) {
        element.innerHTML = `${isStakingPauseText}`;
      });

    if (currentDate > stakeDays && currentDate < endDate) {
      const ele = document.getElementById("countdown-time-value");
      generateCountDown(ele, endDate);

      document.getElementById(
        "countdown-title-value"
      ).innerHTML = `Staking Ends In`;
    }

    if (currentDate < startDate) {
      const ele = document.getElementById("countdown-time-value");
      generateCountDown(ele, endDate);

      document.getElementById(
        "countdown-title-value"
      ).innerHTML = `Staking Starts In`;
    }

    document.querySelectorAll(".apy-value").forEach(function (element) {
      element.innerHTML = `${cApy} %`;
    });
  } catch (error) {
    console.log(error);
    notyf.error(
      `Unable to fetch data from ${SELECT_CONTRACT[_NETWORK_ID].network_name}`
    );
  }
}

function generateCountDown(ele, claimDate) {
  clearInterval(countDownGlobal);
  var countDownDate = new Date(claimDate).getTime();

  countDownGlobal = setInterval(function () {
    var now = new Date().getTime();
    var distance = countDownDate - now;

    var days = Math.floor(distance / (1000 * 60 * 60 * 24));
    var hours = Math.floor(
      (distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)
    );
    var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
    var secends = Math.floor((distance % (1000 * 60)) / 1000);

    ele.innerHTML = `${days}d ${hours}h ${minutes}m ${secends}s`;

    if (distance < 0) {
      clearInterval(countDownGlobal);
      ele.html("Refresh page");
    }
  }, 1000);
}

async function connectMe(_provider) {
  try {
    let _comn_res = await commonProviderDetector(_provider);
    console.log(_comn_res);
    if (!_comn_res) {
      console.log("please connect");
    } else {
      let sClass = getSelectedTab();
      console.log(sClass);
    }
  } catch (error) {
    notyf.error(error.message);
  }
}

async function stackTokens() {
  try {
    let nTokens = document.getElementById("amount-to-stack-value-new").value;
    if (!nTokens) {
      return;
    }

    if (isNaN(nTokens) || nTokens == 0 || Number(nTokens) < 0) {
      console.log("Invalid token amount");
      return;
    }

    nTokens = Number(nTokens);

    let tokenToTransfer = addDecimal(nTokens, 18);

    console.log("tokenToTransfer", tokenToTransfer);

    let balMainUser = await oContractToken.methods
      .balanceOf(currentAddress)
      .call();
    balMainUser = Number(balMainUser) / 10 ** 18;
    console.log("balMainUser", balMainUser);

    if (balMainUser < nTokens) {
      notyf.error(
        `insufficient token on ${SELECT_CONTRACT[_NETWORK_ID].network_name}`
      );
      return;
    }

    let sClass = getSelectedTab(contractCall);
    console.log(sClass);

    let balMainAllowance = await oContractToken.methods
      .allowance(
        currentAddress,
        SELECT_CONTRACT[_NETWORK_ID].STAKING[sClass].address
      )
      .call();

    if (Number(balMainAllowance) < Number(tokenToTransfer)) {
      approveTokenSpend(tokenToTransfer, sClass);
    } else {
      stackTokenMain(tokenToTransfer, sClass);
    }
  } catch (error) {
    console.log(error);
    notyf.dismiss(notification);
    notyf.error(formatEthErrorMsg(error));
  }
}

async function approveTokenSpend(_mint_fee_wei, sClass) {
  let gasEstimation;

  try {
    gasEstimation = await oContractToken.methods
      .approve(
        SELECT_CONTRACT[_NETWORK_ID].STAKING[sClass].address,
        _mint_fee_wei
      )
      .estimateGas({
        from: currentAddress,
      });
  } catch (error) {
    console.log(error);
    notyf.error(formatEthErrorMsg(error));
    return;
  }

  oContractToken.methods
    .approve(
      SELECT_CONTRACT[_NETWORK_ID].STAKING[sClass].address,
      _mint_fee_wei
    )
    .send({
      from: currentAddress,
      gas: gasEstimation,
    })
    .on("transactionHash", (hash) => {
      console.log("Transaction Hash:", hash);
    })
    .on("receipt", (receipt) => {
      console.log(receipt);
      stackTokenMain(_mint_fee_wei);
    })
    .catch((error) => {
      console.log(error);
      notyf.error(formatEthErrorMsg(error));
      return;
    });
}

async function stackTokenMain(_amount_wei, sClass) {
  let gasEstimation;

  let oContractStaking = getContractObj(sClass);

  try {
    gasEstimation = await oContractStaking.methods
      .stack(_amount_wei)
      .estimateGas({
        from: currentAddress,
      });
  } catch (error) {
    console.log(error);
    notyf.error(formatEthErrorMsg(error));
    return;
  }

  oContractStaking.methods
    .stake(_amount_wei)
    .send({
      from: currentAddress,
      gas: gasEstimation,
    })
    .on("receipt", (receipt) => {
      console.log(receipt);
      const receiptObj = {
        token: _amount_wei,
        from: receipt.from,
        to: receipt.to,
        blockHash: receipt.blockHash,
        blockNumber: receipt.blockNumber,
        cumulativeGasUsed: receipt.cumulativeGasUsed,
        effectiveGasPrice: receipt.effectiveGasPrice,
        gasUsed: receipt.gasUsed,
        status: receipt.status,
        transactionHash: receipt.transactionHash,
        type: receipt.type,
      };

      let transactionHistory = [];

      const allUserTransaction = localStorage.getItem("transactions");

      if (allUserTransaction) {
        transactionHistory = JSON.parse(allUserTransaction);
        transactionHistory.push(receiptObj);
        localStorage.setItem(
          "transactions",
          JSON.stringify(transactionHistory)
        );
      } else {
        transactionHistory.push(receiptObj);
        localStorage.setItem(
          "transactions",
          JSON.stringify(transactionHistory)
        );
      }

      console.log(allUserTransaction);
      window.location.href = "http://127.0.0.1:5500/analytic.html";
    })
    .on("transactionHash", (hash) => {
      console.log("Transaction hash: ", hash);
    })
    .catch((error) => {
      console.log(error);
      notyf.error(formatEthErrorMsg(error));
      return;
    });
}

async function unstakeTokens() {
  try {
    let nTokens = document.getElementById("amount-to-unstack-value").value;
    if (!nTokens) return;
    if (isNaN(nTokens) || nTokens == 0 || Number(nTokens) < 0) {
      notyf.error(`Invalid token amount`);
      return;
    }
    nTokens = Number(nTokens);

    let tokenToTransfer = addDecimal(nTokens, 18);

    let sClass = getSelectedTab(contractCall);
    let oContractStaking = getContractObj(sClass);

    let balMainUser = await oContractStaking.methods
      .getUser(currentAddress)
      .call();
    balMainUser = Number(balMainUser.stakeAmount) / 10 ** 18;

    if (balMainUser < nTokens) {
      notyf.error(
        `insufficient token on ${SELECT_CONTRACT[_NETWORK_ID].network_name}`
      );
      return;
    }

    unstakeTokensMain(tokenToTransfer, oContractStaking, sClass);
  } catch (error) {
    console.log(error);
    notyf.dismiss(notification);
    notyf.error(formatEthErrorMsg(error));
  }
}

async function unstackTokenMain(_amount_wei, oContractStaking, sClass) {
  let gasEstimation;

  try {
    gasEstimation = oContractStaking.methods.unstake(_amount_wei).estimateGas({
      from: currentAddress,
    });
  } catch (error) {
    console.log(error);
    notyf.error(formatEthErrorMsg(error));
    return;
  }

  oContractStaking.methods
    .unstake(_amount_wei)
    .send({
      from: currentAddress,
      gas: gasEstimation,
    })
    .on("receipt", (receipt) => {
      console.log(receipt);
      const receiptObj = {
        token: _amount_wei,
        from: receipt.from,
        to: receipt.to,
        blockHash: receipt.blockHash,
        blockNumber: receipt.blockNumber,
        cumulativeGasUsed: receipt.cumulativeGasUsed,
        effectiveGasPrice: receipt.effectiveGasPrice,
        gasUsed: receipt.gasUsed,
        status: receipt.status,
        transactionHash: receipt.transactionHash,
        type: receipt.type,
      };

      let transactionHistory = [];

      const allUserTransaction = localStorage.getItem("transactions");
      if (allUserTransaction) {
        transactionHistory = JSON.parse(allUserTransaction);
        transactionHistory.push(receiptObj);
        localStorage.setItem(
          "transactions",
          JSON.stringify(transactionHistory)
        );
      } else {
        transactionHistory.push(receiptObj);
        localStorage.setItem(
          "transactions",
          JSON.stringify(transactionHistory)
        );
      }

      window.localtion.href = "http://127.0.0.1:5500/analytic.html";
    })
    .on("transactionHash", (hash) => {
      console.log("Transaction hash: ", hash);
    })
    .catch((error) => {
      console.log(error);
      notyf.error(formatEthErrorMsg(error));
      return;
    });
}

async function claimTokens() {
  try {
    let sClass = getSelectedTab(contractCall);
    let oContractStaking = getContractObj(sClass);

    let rewardBal = await oContractStaking.methods
      .getUserEstimatedRewards()
          .call({ from: currentAddress });
      rewardBal = Number(rewardBal);

      console.log("rewardBal", rewardBal);
      
      if (!rewardBal) {
          notyf.dismiss(notification)
          notyf.error(`No rewards to claim`);
          return;
      }

      claimTokensMain(oContractStaking,sClass)

  } catch (error) {
      console.log(error)
      notyf.dismiss(notification)
      notyf.error(formatEthErrorMsg(error))
  }
}

async function claimTokenMain(oContractStaking, sClass) {
    let gasEstimation;
    try {
        gasEstimation = await oContractStaking.methods.claimReward().estimateGas({
            from: currentAddress
        })
        console.log("gasEstimation", gasEstimation);
    } catch (error) {
        console.log(error)
        notyf.error(formatEthErrorMsg(error))
        return;
    }

    oContractStaking.methods.claimReward().send({
        from: currentAddress,
        gas: gasEstimation
    }).on("reciept", (reciept) => { 
        console.log(reciept)
        const recieptObj = {
            token: _amount_wei,
            from: reciept.from,
            to: reciept.to,
            blockHash: reciept.blockHash,
            blockNumber: reciept.blockNumber,
            cumulativeGasUsed: reciept.cumulativeGasUsed,
            effectiveGasPrice: reciept.effectiveGasPrice,
            gasUsed: reciept.gasUsed,
            status: reciept.status,
            transactionHash: reciept.transactionHash,
            type: reciept.type
        }

        let transactionHistory = []

        const allUserTransaction = localStorage.getItem("transactions")
        if (allUserTransaction) {
            transactionHistory = JSON.parse(allUserTransaction)
            transactionHistory.push(recieptObj)
            localStorage.setItem("transactions", JSON.stringify(transactionHistory))
        } else {
            transactionHistory.push(recieptObj)
            localStorage.setItem("transactions", JSON.stringify(transactionHistory))
        }
        window.location.href = "http://127.0.0.1:5500/analytic.html"
    }).on("transactionHash", (hash) => {
        console.log("Transaction hash: ", hash)
    }).catch((error) => {
        console.log(error)
        notyf.error(formatEthErrorMsg(error))
        return;
    })
}
