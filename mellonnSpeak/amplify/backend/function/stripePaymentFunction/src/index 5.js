const awsServerlessExpress = require('aws-serverless-express');
const app = require('./app');

const server = awsServerlessExpress.createServer(app);

exports.handler = (event, context) => {
    console.log(`EVENT: ${JSON.stringify(event)}`);
    const stripe = require("stripe")("sk_test_51K1CskBLC2uA76LRFJrdtxDlDy1lLjry796RWVBInLSyj0tLd3hfuRrVopnNZZTsHUF2FXWVPU54jcIiXomYcWnp00WPxvYUl3");
    const { email, amount, currency } = JSON.parse(event.body);

    try {
        let customerId;

        //Gets the customer who's email id matches the one sent by the client
        const customerList = await stripe.customers.list({
            email: email,
            limit: 1
        });
                
        //Checks the if the customer exists, if not creates a new customer
        if (customerList.data.length !== 0) {
            customerId = customerList.data[0].id;
        }
        else {
            const customer = await stripe.customers.create({
                email: email
            });
            customerId = customer.data.id;
        }

        //Creates a temporary secret key linked with the customer 
        const ephemeralKey = await stripe.ephemeralKeys.create(
            { customer: customerId },
            { apiVersion: '2020-08-27' }
        );

        //Creates a new payment intent with amount passed in from the client
        const paymentIntent = await stripe.paymentIntents.create({
            amount: parseInt(amount),
            currency: currency,
            customer: customerId,
        })

        console.log('Payment intent: ' + paymentIntent.client_secret + ', EphemeralKey: ' + ephemeralKey.secret + ', Customer: ' + customerId);

        return {
            statusCode: 200, // http status code
            body: JSON.stringify({
                paymentIntent: paymentIntent.client_secret,
                ephemeralKey: ephemeralKey.secret,
                customer: customerId,
                success: true,
            }),
        };

    } catch (error) {
        console.log('ERROR: ' + error.message);
        return {
            statusCode: 404,
            body: JSON.stringify({success: false, error: error.message}),
        }
    }
};