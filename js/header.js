const _NETWORK_ID = 80001;
let SELECT_CONTRACT = {};

SELECT_CONTRACT[_NETWORK_ID] = {
    network_name: "Polygon Mumbai",
    explorer_url: "http://mumbai.polygonscan.com/",
    STAKING: {
        sevenDays: {
            address: "",
        },
        tenDays: {
            address: ""
        },
        thirtyTwoDays: {
            address: ""
        },
        ninetyDays: {
            address: ""
        },
        abi: [],
    },
    TOKEN: {
        symbol: "TBC",
        address: "",
        abi: []
    }
};

let countDownGlobal;

let web3;

let oContractToken;

let contractCall = "sevenDays";

let currentAddress;

let web3Main = new Web3("https://rpc.ankr.com/polygon_mumbai");

var notyf = new Notyf({
    duration: 3000,
    position: { x: "right", y: "bottom" },
})

