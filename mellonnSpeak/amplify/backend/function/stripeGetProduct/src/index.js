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
/* Amplify Params - DO NOT EDIT
	ENV
	REGION
Amplify Params - DO NOT EDIT */

/**
 * @type {import('@types/aws-lambda').APIGatewayProxyHandler}
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
    
    const group = JSON.parse(event.body).group;
    const currency = JSON.parse(event.body).currency;

    let product = process.env.product;
    if (group == 'benefit') product = process.env.benefitProduct;

    try {
        console.log('Getting product: ' + product);

        const productResponse = await stripe.products.retrieve(product);
        console.log('Product: ' + JSON.stringify(productResponse));

        const priceResponse = await stripe.prices.retrieve(
            productResponse.default_price,
            {expand: ['currency_options']}
        );
        console.log('Price: ' + JSON.stringify(priceResponse));

        let currencyPrice = priceResponse;
        let returnCurrency = priceResponse.currency;

        try {
            currencyPrice = priceResponse.currency_options[currency.toLowerCase()];
            returnCurrency = currency;
            console.log('Price asked for: ' + currencyPrice.unit_amount);
        } catch (err) {
            console.log(`Currency (${currency}) isn't in the system`);
            currencyPrice = priceResponse;
        }

        return {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "*"
            }, 
            body: JSON.stringify({
                product: productResponse,
                price: currencyPrice,
                currency: returnCurrency,
            }),
        };
    } catch (err) {
        console.log(`Error: ${err}`);

        return {
            statusCode: 500,
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "*"
            }, 
            body: JSON.stringify(err),
        };
    }

    
};
