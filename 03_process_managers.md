# Process Manager Conventions

`_This is a work in progress_`. Updated on 11/24/2025

Process managers are a convention that AI agents need to organize an unRESTful process. This is commonly domain specific business logic or workflows.

A process manager name is a statement or phrase that describes what is being done.

Let’s use an example of building a report. We are just going to describe the feature story that defines this process, and the triggering event. For this example our app has Customers:&#x20;

`When a list of Customer ID’s is provided, then lock each customers account.`

Processes start with a “when” keyword, always. Because a process is “when” something happens!

The second statement “a list of Customer ID’s is provided” tells us the qualifying information we need before this process can be performed. Here were are referencing a “list” aka an Array of IDs which is the attribute type from the Customer model. This could be integers, ULID, UUID’s etc.

The second half “lock each customers account” is using jargon that represents an operation we define for the business. “Locking” an account for this means: changing an attribute in the Customer model that requires an additional input from the user to confirm their identity and reset their password.

A process manager can perform many operations at a time, and typically will. The more complicated the process, the more likely to require human intervention to write the complete the process writing.

If we expand our process statement, it looks like the following:

`When an array of Integers that represent Customer IDs is provided then loop through each Customer account using the ID to find the correct record and update the necessary attribute that will prevent the Customer from accessing their account.`

The AI is going to analyze this and ultimately make the determination if any jargon was used, and will ask questions if it can’t understand your intent. It will generally phrase it like I explained above, and may provide more details.

---

*Chapter 03 of the AED canon · published **verbatim** from the author's original (last revised 2025-11-24); the work-in-progress marker at the top is his own, kept as written · continue to [04 · Feature Stories](04_feature_stories.md) · [reading order](README.md#reading-order)*
