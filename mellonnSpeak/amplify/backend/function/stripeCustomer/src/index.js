
exports.handler = async (event) => {
    const stripe = require("stripe")(process.env.stripeKey);
    const email = event.email;

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
        body: customerId,
    };
};
