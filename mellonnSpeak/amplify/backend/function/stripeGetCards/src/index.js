/*
Use the following code to retrieve configured secrets from SSM:

const aws = require('aws-sdk');

const { Parameters } = await (new aws.SSM())
  .getParameters({
    Names: ["stripeKey"].map(secretName => process.env[secretName]),
    WithDecryption: true,
  })
  .promise();

Parameters will be of the form { Name: 'secretName', Value: 'secretValue', ... }[]
*/
exports.handler = async (event) => {
    const aws = require('aws-sdk');
    
    const { Parameters } = await (new aws.SSM())
  .getParameters({
    Names: ["stripeKey"].map(secretName => process.env[secretName]),
    WithDecryption: true,
  })
  .promise();

    const stripe = require("stripe")(Parameters[0].Value);
    const customerId = JSON.parse(event.body).customerId;

    let cards;

    try {
        cards = await stripe.paymentMethods.list({
            customer: customerId,
            type: 'card',
        });
    } catch (err) {
        console.log(err);
        return {
            statusCode: 500,
            headers: {
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
            },
            body: JSON.stringify({
                error: err.message,
            })
        }
    }
    
    return {
        statusCode: 200,
        headers: {
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
        },
        body: JSON.stringify(cards),
    };
};
