exports.handler = async (event) => {
    const stripe = require("stripe")(process.env.stripeKey);
    const body = JSON.parse(event.body);
    const customerId = body.customerId;

    try {
        const setupIntent = await stripe.setupIntents.create({
            customer: customerId,
        });

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
        body: setupIntent.client_secret,
    };
};
