/*:
 # WriteFreely Swift Package: Playground Sample
 
 * Note:
    To view this Playground as documentation, go to **Editor** > **Show Rendered Markup**.
 */
import Foundation
import WriteFreely

/*:
 * Important:
    To test the WriteFreely package in this Playground, you'll need to set up an account on an open WriteFreely instance
    first. You can find **Open** instances at [writefreely.org/instances](https://writefreely.org/instances), or create
    a free account on [Write.as](https://write.as). Once that's done, supply your `username`, `password`, and `instance`
    to the constants below.
 */
let username: String = "username"
let password: String = "password"
let instance: String = "https://write.as"

/*:
 * callout(The Plan):
    Next, let's define what we want the app to do:
    1. Log in to your account on the WriteFreely instance,
    2. Publish an anonymous/draft post, and
    3. Log out.
 */
/*:
 * callout(The WFClient):
    Most of what you'll use to interact with the WriteFreely instance are functions vended by the **WFClient**. Let's
    start by initializing it, then log in. Most WFClient functions have a signature like this:
  
    `func methodName(parameter: Type, completion: @escaping (Result<WFType, Error>) -> Void)`
  
    For example, check out the `login` method:
  
    `func login(username: String, password: String, completion: @escaping (Result<WFUser, Error>) -> Void)`
 */
guard let instanceURL = URL(string: instance) else { fatalError() }
let client = WFClient(for: instanceURL)
client.login(username: username, password: password, completion: loginHandler)

/*:
 * callout(The Completion Handlers):
    You might have noticed above that when logging in, we're passing a `loginHandler` to the `completion:` parameter.
    As the function signature shows, this is a closure that takes a `Result<WFUser, Error>` parameter and returns
    nothing. That means that once the WFClient has finished with the login attempt, it'll call this closure, which you
    write to handle both the case of a successful login attempt, or any error, like so:
 */
func loginHandler(result: Result<WFUser, Error>) {
    switch result {
    
    /// If the login attempt was successful, get the returned `WFUser` from the `Result`, print a greeting to the
    /// console, and then call the `createAndPublishSamplePost()` function.
    case .success(let user):
        print("Hi there, \(user.username ?? "anonymous user")!")
        createAndPublishSamplePost()

    /// Otherwise, if the login attempt failed, get the returned `Error`, and print it to the console.
    case .failure(let error):
        print("Oops! \(error)")
    }
}

/*:
 * callout(Publishing A Post):
    When the `loginHander(result:)` function above is called for a successful login attempt, it calls the function below
    to create and publish an draft post to your WriteFreely instance. We start by creating a very simple `WFPost` object
    with a `title` and a `body`, and then pass it in to the `createPost(post:completion:)` function. In this case, we
    write the completion block inline with the function.
 */
func createAndPublishSamplePost() {
    // Prepare a draft post for publishing.
    let draft = WFPost(
        body: "This is a sample post created from the Swift Package playground!",
        title: "My First Draft!"
    )

    // Then, we attempt to publish the post!
    client.createPost(post: draft, completion: { result in
        switch result {

        /// If the post is published successfully, get the returned `WFPost`, print a success message to the console
        /// with a link to the draft, and then call the `logout()` function.
        case .success(let post):
            print("See your post live, here: \(instance)/\(post.postId ?? "")")
            logout()

        /// Otherwise, if the publishing attempt failed, get the returned `Error`, and print it to the console.
        case .failure(let error): print("Oops! \(error)")
        }
    })
}

/*:
 * callout(Logging Out):
    This is very important! When you're done with the session, make sure to call the `logout(completion:)` function to
    make sure that the user's access token is invalidated by the server.
 */
func logout() {
    client.logout(completion: { result in
        switch result {

        /// If the logout attempt is successful, print a success message to the console.
        case .success(_): print("Logged out!")

        /// Otherwise, if the logout attempt failed, get the returned `Error`, and print it to the console.
        case .failure(let error): print("Oops! \(error)")
        }
    })
}
