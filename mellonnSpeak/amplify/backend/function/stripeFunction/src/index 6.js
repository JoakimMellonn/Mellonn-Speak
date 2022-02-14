const awsServerlessExpress = require('aws-serverless-express');
const app = require('./app');

//const server = awsServerlessExpress.createServer(app);

exports.handler = async (event, context) => {
    console.log(`EVENT: ${JSON.stringify(event)}`);
    const stripe = require("stripe")("sk_test_51K1CskBLC2uA76LRFJrdtxDlDy1lLjry796RWVBInLSyj0tLd3hfuRrVopnNZZTsHUF2FXWVPU54jcIiXomYcWnp00WPxvYUl3");
    
    const json = JSON.stringify(event.body);
    console.log(json);
    
    const temp = json.split('&');
    
    let email = decodeURI(temp[0].split('=')[1]);
    let amount = decodeURI(temp[1].split('=')[1]);
    let currency = decodeURI(temp[2].split('=')[1]);
    email = email.replace('%40', '@');
    currency = currency.replace('"', '');
    
    console.log('email: ' + email + ', amount: ' + amount + ', currency: ' + currency);

    try {
        let customerId;

        //Gets the customer who's email id matches the one sent by the client
        const customerList = await stripe.customers.list({
            email: email,
            limit: 1
        });
        
        console.log('json: ' + JSON.stringify(customerList.data));
                
        //Checks the if the customer exists, if not creates a new customer
        if (customerList.data.length !== 0) {
            customerId = JSON.stringify(customerList.data).split(',')[0].split('":"')[1].replace('"', '');
            console.log('ID: ' + customerId);
        }
        else {
            const customer = await stripe.customers.create({
                email: email
            });
            customerId = JSON.stringify(customerList.data).split(',')[0].split('":"')[1].replace('"', '');
        }

        //Creates a temporary secret key linked with the customer 
        const ephemeralKey = await stripe.ephemeralKeys.create(
            { customer: customerId },
            { apiVersion: '2020-08-27' }
        );

        //Creates a new payment intent with amount passed in from the client
        const paymentIntent = await stripe.paymentIntents.create({
            amount: parseInt(amount, 10),
            currency: currency,
            customer: customerId,
        });

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
        };
    }
};