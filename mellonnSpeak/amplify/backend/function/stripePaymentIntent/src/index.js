exports.handler = async (event) => {
    const stripe = require("stripe")(process.env.stripeKey);
    const body = JSON.parse(event.body);
    const customerId = body.customerId;
    const amount = body.amount;
    const currency = body.currency;


    try {
        const intent = await stripe.paymentIntents.create({
            amount: amount,
            currency: currency,
            customer: customerId,
        });

        return {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "*"
            },
            body: {
                paymentIntent: paymentIntent.client_secret,
                ephemeralKey: ephemeralKey.secret,
            }
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
