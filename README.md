## Notes
I created a REST API server using Ruby and Sinatra

The following API endpoints are supported:

GET /v1/register - creates a new user, and returns the API token
GET /v1/login - returns the API token for an existing user
GET /v1/current - get the current integer for the user
GET /v1/next - get the next integer in the sequence for the user
POST /v1/current - set the integer for the user

### Examples:
1. Create a user
```
curl --data "email=$email" --data "password=$password" "http://localhost:4567/v1/register"
> {"token":"eyJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImtlbHNleUBzdGVtbWxlci50ZWNoIn0.IfDsdTSFX5VMF2G_Vc5CJptJBhhyjsaBk7g77zqTNss"}
# Note: if you attempt to create the user again, you will get an error because the user already exists. Instead, you can fetch the API token again by calling the /v1/login endpoint.
```

2. Use the API token in 1, to get the current number
```
curl -H "Authorization: Bearer $API_TOKEN" "http://localhost:4567/v1/current"
> {"integer":1}
```

3. Increment the number
```
curl -H "Authorization: Bearer $API_TOKEN" "http://localhost:4567/v1/next"
> {"integer":2}
```

4. Set the number to 123
```
curl --data "current=123" -H "Authorization: Bearer $API_TOKEN" "http://localhost:4567/v1/current"
> {}
# Note: you can call /v1/current again to validate here, since the POST update doesn't return anything
```

5. Fetch the API token for the existing user (Note: you must use the same email and password in step 1)
```
curl --data "email=$email" --data "password=$password" "http://localhost:4567/v1/login"
> {"api_token":"eyJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImtlbHNleUBzdGVtbWxlci50ZWNoIn0.IfDsdTSFX5VMF2G_Vc5CJptJBhhyjsaBk7g77zqTNss"}
```

### Date
05/07/2020

### Location of deployed application
Once you have the app running locally (see section below), you can access it via:

http://localhost:4567

### Time spent
I spent approximately 4.5 hours developing this application.

### Assumptions made
The following is a list of assumptions I made during this assignment:
- The Integer value begins at value 1. (Traditionally, in Computer Science, we begin counting at 0 for indices, but IDs, we generally want to start at 1.)
- The Integer can be set to an arbitrary, non-negative value. The user does not need to have previously set the number to this value in the past. E.g., The user can start with integer 1, and then set it to 1000. 
- I picked a minimum value of 1, and a maximum value of 1,000,000,000,000 for the Integer, and validate against these bounds. If the user attempts to set or increment above the maximum value, an error will be returned (try it!).
- The API token is passed into the endpoints via HTTP header with the format `Authorization: Bearer $API_TOKEN`, and is only required on endpoints for fetching/incrementing/updating the number. The API token is not used on the registration and login endpoints.


### Shortcuts/Compromises made
There are a few areas that I would focus on, when launching a real-world application.

#### Data Storage: 
I used an in-memory dictionary storage for the user information, with only the necessary fields (email, encrypted password, api_token, and number). Since this is in memory, I decided to keep a maximum number of users at 1000, to protect against any memory issues (though this number can be larger). I would prefer to use a real database to help scale to a large number of users, as well as to be able to enforce validation/types of fields, etc. In that case I would include additionaly user fields such as user id, name, username, phone number, address, creation time, updated time, last login time, etc.

#### Testing
I would not feel comfortable shipping this application without any tests. I would spend time writing unit tests for the various validation functions, API token encoding/decoding, password encryptions, etc. I would also write integration tests to ensure the proper behaviour of fetching, incrementing and setting the integer, and all the failure cases around the registration and login scenarios. I would also test that each user is able to independently take action on their number, without affecting any other user's number.

#### Code Structure
I would love to refactor the code into modules and classes. I kept it all in one file for now, so that it can be easily read for this this assignment.

#### API Best Practices
I would incorporate other API best practices, such as rate limiting the endpoints. Especially for the registration and login flows, to prevent any spam/abusive behaviour.

### Stretch goals attempted
I did not attempt any of the stretch goals. Instead I decided to focus on the main implementation, validation, failure cases, and keeping the code clean with documentation (both embedded in the code and this README). I also spent time manually testing the various scenarios to ensure the right error codes were returned in each scenario, and expected behaviour occurred.
 
### Instructions to run assignment locally
First, ensure that you have Ruby and Bundle installed locally.
_Note: I used Ruby version 2.3.7 and Bundle version 2.1.4_

Next, start the Ruby Sinatra app by running the following commands:
```
bundle install
ruby app.rb
```

### What did you not include in your solution that you want us to know about?
If I had more time, I would have also liked to include features such as the following:
- Deleting an existing user
- Ability to ban/deactivate a user.
- Adding multiple users to an account (1:many relationship), so that developers on the same team can query the service and continue to coordinate on the ID incrementing. I would also add different scopes on each user (e.g., read/write permissions)
- Reset a password for an existing user.
- Ability to logout.
- Ability to re-set an API token, and add an expiration (TTL) to tokens, so that they do not live forever. Instead, they would need to be rotated every N units of time.
- Add logging (especially for the failure cases that would require debugging).
- Add metrics to track the counts of each request coming in, the failures, etc.
- Keep a record of every value a user has set, so that there is an audit trail of which numbers were used, incremented, reset, etc.


### Other information about your submission that you feel it's important that we know if applicable.
N/A, everything is already captured in the previous sections

### Your feedback on this technical challenge
I found that the example curl requests to be very helpful, and appreciate the note at the top about not including name/emails to prevent any bias. Great work!
