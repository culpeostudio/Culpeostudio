package main

// publicGRPCMethods lists the fully qualified gRPC methods that are reachable
// without a bearer token. It is the successor of isPublicAuthRoute in the HTTP
// middleware, and it grows as each module moves over to gRPC.
//
// Two kinds of methods belong here, and nothing else:
//   - the calls that hand out a token in the first place (login, first-run
//     setup, account creation, password reset) plus the status probe the client
//     uses before it has one,
//   - services that authenticate by their own means, such as the memory module
//     with its separate API token.
func publicGRPCMethods() map[string]bool {
	const loginService = "/culpeostudio.login.v1.LoginService/"
	return map[string]bool{
		// Hands out the token everything else is authenticated with.
		loginService + "Login": true,

		// Probed before a token exists, to decide between the first-run setup
		// and the normal login screen.
		loginService + "GetAuthStatus": true,

		// First-run authenticator setup and account creation. These guard
		// themselves with the TOTP code instead of a bearer token.
		loginService + "StartAuthenticatorSetup":   true,
		loginService + "ConfirmAuthenticatorSetup": true,
		loginService + "CreateAccount":             true,

		// Recovery for a user who cannot log in by definition.
		loginService + "ResetPassword": true,
	}
}
