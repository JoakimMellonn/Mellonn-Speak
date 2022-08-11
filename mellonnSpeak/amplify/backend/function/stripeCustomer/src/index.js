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
    const email = JSON.parse(event.body).email;

    let customerId;

    try {
        const customerList = await stripe.customers.list({email: email, limit: 1});

        if (customerList.data.length > 0) {
            customerId = customerList.data[0].id;
        } else {
            const customer = await stripe.customers.create({email: email});
            customerId = customer.id;
        }

    } catch (err) {
        console.log(err);
        return {
            statusCode: 500,
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "*"
            },
            body: JSON.stringify({
                message: err.message
            })
        };
    }

    return {
        statusCode: 200,
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "*"
        }, 
        body: JSON.stringify(customerId),
    };
};
