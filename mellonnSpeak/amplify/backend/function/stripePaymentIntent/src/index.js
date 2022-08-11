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

    const stripe = require("stripe")(
        Parameters[0].Value,
        {
            apiVersion: '2020-08-27; orders_beta=v4'
        }
    );
    const body = JSON.parse(event.body);

    const customerId = body.customerId;
    const currency = body.currency;
    const product = body.product;
    const quantity = body.quantity;
    const name = body.name;
    const country = body.country;
    const postalCode = body.postalCode;


    try {
        const order = await stripe.orders.create({
            customer: customerId,
            currency: currency,
            line_items: [
                {
                    product: product,
                    quantity: quantity
                },
            ],
            shipping_details: {
                name: name,
                address: {
                    postal_code: postalCode,
                    country: country,
                },
            },
            automatic_tax: {enabled: true},
        });

        return {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "*"
            },
            body: JSON.stringify(order.client_secret),
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
        }
    }
};
