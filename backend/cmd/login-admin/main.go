package main

import (
	"errors"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/fillyengine/backend/modules/login"
)

func main() {
	defaultAccountsFile := os.Getenv("LOGIN_ACCOUNTS_FILE")
	if strings.TrimSpace(defaultAccountsFile) == "" {
		defaultAccountsFile = "data/login_accounts.json"
	}
	defaultAuthConfigFile := os.Getenv("AUTH_CONFIG_FILE")
	if strings.TrimSpace(defaultAuthConfigFile) == "" {
		defaultAuthConfigFile = "data/login_authenticator.json"
	}

	action := flag.String("action", "", "action to execute: create|list|get|delete")
	username := flag.String("username", "", "username for create|get|delete")
	password := flag.String("password", "", "password for create")
	totpCode := flag.String("totp-code", "", "Google Authenticator code for create")
	accountsFile := flag.String("accounts-file", defaultAccountsFile, "path to login accounts json file")
	authConfigFile := flag.String("auth-config-file", defaultAuthConfigFile, "path to authenticator config json file")
	flag.Parse()

	store := login.NewAccountStore(*accountsFile)
	if err := store.Load(); err != nil {
		log.Fatalf("accounts could not be loaded: %v", err)
	}

	switch strings.ToLower(strings.TrimSpace(*action)) {
	case "create":
		authStore := login.NewAuthenticatorStore(*authConfigFile)
		handleCreate(store, authStore, *username, *password, *totpCode)
	case "list":
		handleList(store)
	case "get":
		handleGet(store, *username)
	case "delete":
		handleDelete(store, *username)
	default:
		log.Fatal("usage: go run ./cmd/login-admin -action <create|list|get|delete> [-username <name>] [-password <password>] [-totp-code <code>] [-accounts-file <path>] [-auth-config-file <path>]")
	}
}

func handleCreate(store *login.AccountStore, authStore *login.AuthenticatorStore, username, password, totpCode string) {
	if strings.TrimSpace(username) == "" || strings.TrimSpace(password) == "" {
		log.Fatal("create requires -username and -password")
	}
	if strings.TrimSpace(totpCode) == "" {
		log.Fatal("create requires -totp-code")
	}
	if err := authStore.Load(); err != nil {
		log.Fatalf("authenticator could not be loaded: %v", err)
	}
	if !authStore.IsConfigured() {
		log.Fatal("authenticator is not configured")
	}
	if !authStore.ValidateCode(totpCode, time.Now()) {
		log.Fatal("invalid authenticator code")
	}

	if err := store.CreateUser(username, password); err != nil {
		if errors.Is(err, login.ErrUserExists) {
			log.Fatalf("account already exists: %s", strings.TrimSpace(username))
		}
		log.Fatalf("could not write account: %v", err)
	}

	fmt.Printf("Account '%s' saved in %s\n", strings.TrimSpace(username), store.Path())
}

func handleList(store *login.AccountStore) {
	users := store.ListUsers()
	if len(users) == 0 {
		fmt.Println("No users found")
		return
	}

	for _, user := range users {
		fmt.Println(user)
	}
}

func handleGet(store *login.AccountStore, username string) {
	clean := strings.TrimSpace(username)
	if clean == "" {
		log.Fatal("get requires -username")
	}

	if store.UserExists(clean) {
		fmt.Printf("FOUND:%s\n", clean)
		return
	}

	fmt.Printf("NOT_FOUND:%s\n", clean)
	os.Exit(1)
}

func handleDelete(store *login.AccountStore, username string) {
	clean := strings.TrimSpace(username)
	if clean == "" {
		log.Fatal("delete requires -username")
	}

	deleted, err := store.DeleteUser(clean)
	if err != nil {
		log.Fatalf("could not delete account: %v", err)
	}
	if !deleted {
		fmt.Printf("NOT_FOUND:%s\n", clean)
		os.Exit(1)
	}

	fmt.Printf("DELETED:%s\n", clean)
}
