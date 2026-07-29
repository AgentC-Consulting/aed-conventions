# Agent Enhanced Development - The Whole Process

## Introduction To What A Feature Request Is
The idea of “operating” an AI means we need to be able to define it’s “operations” to begin with.

An operation is essentially the work flow for performing a task. This should encompass multiple steps and possibly “tasks” depending on how you want to define a task.

To operate an AI agent successfully, we have to shift our mindset on a few topics, such as:

1. How we define the work that we want to perform
2. The expected patterns or overall flexibility we have in our code base
3. Our definition of naming conventions and what "clear" means for us
4. How we perform development work
5. The relationship between the code we write and how it reflects the business

To begin with, we are going to start by more clearly defining what a `feature request` really is. If you've been a developer for any period of time, you've most likely already worked with scrum or agile and been exposed to User Stories. The idea here is pretty similar, however instead of managing the details of the story from a 3rd party tool such as Jira, we are going to manage the details directly with our AI agent that works from our code base.

Let's define some critical terminology before we move forward.

**Operation**: the interaction with the AI agent and ensuring it has the correct knowledge and understanding to perform.


## Our First Feature Request
Let’s describe some default operations that should come with the framework. I have notes about user stories and I think that operating an AI development agent should mean using Feature Stories to control the behavior of the agent and the outcome.

First a simple user story:

`As an **Admin** user, I want to _create_ a new **user** **_and_** _assign_ them to an **account**`

This story is pretty simple and would mean operations that are required use the typical MVC concepts, which makes things easy to start with.  

The `As an Admin` establishes our persona, scoping the following **action** to be performed. When there is a persona we have chosen, we also know the feature request requires a view and a controller action at a minimum. Our agent knows which views belong to which controller actions, and if we need to create that controller, action, view etc.

The action is the full statement. It should be a clear summary of what would complete a request/response cycle. If it triggers or enqueues a background job, that should be stated. The action description should also include references to any data models that require a relationship. In the example that’s User and Account. The plurality of the data models dictates the relationships between them, and should use the same Active Record pattern expressions as in Rails.

The “I want to” part is provided as part of the story builder. The action verb needs to be an HTTP verb of GET POST PUTS PATCH or DELETE followed by the primary data model that is effected.

A unique verb of “perform” can be used to trigger a workflow that is not RESTful. This is the keyword you primarily use for our unique business logic, aka your special sauce.

The specially called out “and” in the action is because we follow up a simple RESTful action with a secondary action, and it’s establishing a relationship with an additional record. In this case I highlighted “assign” because it’s an example of company jargon that can alias an Active Record relationship of “belongs to”. These kinds of aliases can be configured with restrictions/conditions before creating a feature story. This story implies it is limited to linking the newly created user to an existing account, and that it does not create a new account.

A feature story with a persona breaks down it’s structure like this:

`As a (specify persona), I want to (RESTful verb, or “perform”) (“a” or “multiple”) (data model name of an existing data model) and (AR relationship name/type or “perform”) (data model name or Process Manager name if performing a process)`

A “persona” is a specialized alias of a User data model type that includes an indication of the “authorization” (ie permissions) level of that model type. For example, an Admin persona could be an alias of a Super Administrator type that has unrestricted permissions, which means they would be using controllers/routes that are scoped to this kind of user.

Authorization levels work in several ways together to create a robust authorization system.

- Model type: the model name should represent the general permission level of that group. This is resource based, so an Administrator user type may have its own API and all administrators would generally be considered to use those end-points.
- Action specific: RESTful verbs have a matching permission level two on the actual model as an attribute. Your app configuration should define if by default the user of that group is allowed or disallowed, and if the flag necessary to perform the action needs to be specified on the models record.
- Individual resource: individual resources can restrict behavior to model type or record ID’s.

For unRESTful end-points, the permissions are based on if the model type or specific records of models are allowed to execute an action.


## Breakdown of The Anatomy of A Feature Request

TBD

---

*Chapter 04 of the AED canon · published **verbatim** from the author's original. The closing `TBD` is the author's own — the anatomy breakdown is genuinely unwritten, and this release candidate marks it rather than papering over it · continue to [05 · Edit-Level Style](05_edit_level_style.md) · [reading order](README.md#reading-order)*
