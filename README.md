## Notes
*Please do not supply your name or email address in this document. We're doing our best to remain unbiased.*

12:30 - 2 : 1.5
5-7 : 2
9-10 : 1

assumptions:
- can reset to any number (does not need to have been that value in the past)
- supporting BigDecimal and larger values (future idea)

- not necessary to write final returns, but I find it easier for debugging

- if going with logout endpoint, use post! https://stackoverflow.com/questions/3521290/logout-get-or-post
- better validation on the email and password
- disallow any routes outside of the scope?
- can a user reset their api token? add a TTL to it
- what is the maximum number allowed? should we reset?
- different users are independently increasing their current number

- Assumes "Bearer XXXX" and fails auth if not

- restructure the code into proper module/class
- should conform to JSON api standards

FUTURE IDEAS:
- add logging. especially error logging for the failure cases
- add metrics, to count the number of requests coming in 
- more documentation directly in the code
- keep record of every value, so they have a record for auditing purposes of which numbers were used and incremented vs. overidden and reset
- delete a user
- set a user id
- TESTS!!
- password reset
- TTL on the api token, and ability to reset
- ability to ban/deactivate users
- add multiple users to an account (1:many relationship), so that developers on the same team can query the service and continue to coordinate on the ID incrementing
 --- include different scopes (e.g., read/write permissions)
- API rate limiting (especially on the password login to detect spam/abusive behaviour of trying to guess the password)
- more fields for the user (name, phone number, address, createdAt, updatedAt, lastLoginTime, etc.)
- use Rails
- ability to re-fetch the API token

### Date
The date you're submitting this.

### Location of deployed application
If applicable, please provide the url where we can find and interact with your running application.

### Time spent
How much time did you spend on the assignment? Normally, this is expressed in hours.

### Assumptions made
Use this section to tell us about any assumptions that you made when creating your solution.
- start the number at 1. Traditionally, in Computer Science, we begin counting at 0 for indices, but IDs, we generally want to start at 1.

### Shortcuts/Compromises made
If applicable. Did you do something that you feel could have been done better in a real-world application? Please let us know.
- using a database to help scale to a large number of users
- 

### Stretch goals attempted
If applicable, use this area to tell us what stretch goals you attempted. What went well? What do you wish you could have done better? If you didn't attempt any of the stretch goals, feel free to let us know why.
 
### Instructions to run assignment locally
If applicable, please provide us with the necessary instructions to run your solution.

### What did you not include in your solution that you want us to know about?
Were you short on time and not able to include something that you want us to know about? Please list it here so that we know that you considered it.

### Other information about your submission that you feel it's important that we know if applicable.

### Your feedback on this technical challenge
Have feedback for how we could make this assignment better? Please let us know.
