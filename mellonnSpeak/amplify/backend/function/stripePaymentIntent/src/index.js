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
    const body = JSON.parse(event.body);

    const customerId = body.customerId;
    const currency = body.currency;
    const product = body.product;
    const quantity = body.quantity;
    const country = body.country;
    const postalCode = body.postalCode;


    try {
        const price = await getPrice(stripe, product, currency);

        await stripe.customers.update(
            customerId,
            {
                address: {
                    postal_code: postalCode,
                    country: country,
                },
            }
        );

        const calculation = await stripe.tax.calculations.create({
            customer: customerId,
            currency: price.currency,
            line_items: [
                {
                    product: product,
                    amount: price.unit_amount,
                    reference: price.id,
                    quantity: quantity,
                    tax_behavior: "inclusive",
                },
            ]
        });
        
        const paymentIntent = await stripe.paymentIntents.create({
            currency: currency,
            amount: calculation.amount_total,
            metadata: {calculation: calculation.id},
            automatic_payment_methods: {enabled: true},
        });

        return {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "*"
            },
            body: JSON.stringify(paymentIntent.client_secret),
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

async function getPrice(stripe, product, currency) {

    const productResponse = await stripe.products.retrieve(product);

    const priceResponse = await stripe.prices.retrieve(
        productResponse.default_price,
        {expand: ['currency_options']}
    );

    let currencyPrice = priceResponse;
    let currencySupported = true;

    try {
        currencyPrice = priceResponse.currency_options[currency.toLowerCase()];
    } catch (err) {
        currencySupported = false;
        currencyPrice = priceResponse;
    }

    return {
        currency: currencySupported ? currency : currencyPrice.currency,
        unit_amount: currencyPrice.unit_amount,
        id: priceResponse.id,
    };
}