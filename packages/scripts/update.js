//@ts-check
import { ethers } from 'ethers'
import fetch from 'node-fetch'
import { std as calculateStandardDeviation, mean } from 'mathjs'
import { RISK_ENGINE_ABI, RISK_ENGINE_ADDRESS } from './constant.js'
import dotenv from 'dotenv'
dotenv.config()
const updateFeeByAddress = async (address) => {
    const graphqlUrl = 'https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3'
    const provider = new ethers.providers.JsonRpcProvider('https://docs-demo.quiknode.pro/')
    const _blockNumber = await provider.getBlockNumber()
    const pricePromises = []
    console.log('block number', _blockNumber)
    for (let currentBlock = _blockNumber; currentBlock > _blockNumber - 1000; currentBlock = currentBlock - 50) {
        pricePromises.push(fetch(graphqlUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                query: `query ($blockNumber: Int!) {
                pool(
                  id: 
              "${address}"
                  block: {number: $blockNumber}
                ) {
                  tick
                  token0Price
                  token1Price
                  __typename
                }
              }`,
                variables: {
                    blockNumber: currentBlock
                }
            })
        }))
    }
    const prices = await Promise.all(pricePromises).then(async (responses) => {
        const jsons = await Promise.all(responses.map((response) => response.json()))
        //@ts-ignore
        return jsons.map((json) => Number(json.data.pool.token0Price))
    })
    console.log(prices)
    const volatilityArray = []

    //@ts-ignore
    volatilityArray.push(calculateStandardDeviation(prices.slice(0, 5)) / mean(prices.slice(0, 5)))
    //@ts-ignore
    volatilityArray.push(calculateStandardDeviation(prices.slice(0, 10)) / mean(prices.slice(0, 10)))
    //@ts-ignore
    volatilityArray.push(calculateStandardDeviation(prices.slice(0, 20)) / mean(prices.slice(0, 20)))

    const inputData = JSON.stringify([volatilityArray])
    const network = {
        name: 'VANNA TESTNET', // You can use any name to identify the network
        chainId: 901, // Ganache chain ID, replace with the appropriate chain ID if necessary
    };
    console.log('inputData', inputData)
    const vannaProvider = new ethers.providers.JsonRpcProvider('http://dev-rpc.vannalabs.ai:9545', network);
    const vannaWallet = new ethers.Wallet(process.env.PRIVATE_KEY || "", vannaProvider);
    const riskEngineContract = new ethers.Contract(RISK_ENGINE_ADDRESS, RISK_ENGINE_ABI, vannaWallet);
    const tx = await riskEngineContract['setRiskMetricByToken'](address, inputData, {
        gasLimit: 10000000
    })
    await tx.wait()
    console.log(tx)
}
while (true) {
    const pools = ["0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640", "0xcbcdf9626bc03e24f779434178a73a0b4bad62ed", "0xa6cc3c2531fdaa6ae1a3ca84c2855806728693e8", "0x11950d141ecb863f01007add7d1a342041227b58", "0x1d42064fc4beb5f8aaf85f4617ae8b3b5b8bd801"]
    //eth wbtc link pepe uni
    for (let i = 0; i < pools.length; i++) {
        await updateFeeByAddress(pools[i])
    }
    await updateFeeByAddress()
    await new Promise(resolve => setTimeout(resolve, 10000));
}
// const tx = await vannaContract['getVolatility']()
// await tx.wait()
// console.log(tx)