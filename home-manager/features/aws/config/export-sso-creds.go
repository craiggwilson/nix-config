package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"time"
)

var (
	credsCacheDir     string
	errDoneTraversing = errors.New("done")
)

type awsCreds struct {
	AccessKeyID     string    `json:"AccessKeyId"`
	SecretAccessKey string    `json:"SecretAccessKey"`
	SessionToken    string    `json:"SessionToken"`
	Expiration      time.Time `json:"Expiration"`
}

func main() {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		log.Printf("failed to get user home directory: %v", err)
		os.Exit(1)
	}
	credsCacheDir = path.Join(homeDir, ".aws", "cli", "cache")

	var creds *awsCreds
	for i := 0; i < 2; i++ {
		creds, err = tryGetCreds()
		if creds != nil {
			printCreds(creds)
			os.Exit(0)
		}

		if err := runAWSCommand(); err != nil {
			log.Printf("error executing AWS command: %v", err)
		}
	}

	log.Println("failed to get valid credentials; maybe run `aws sso login`?")
	if err != nil {
		log.Printf("last seen error: %v", err)
	}
	os.Exit(1)
}

func tryGetCreds() (*awsCreds, error) {
	if _, err := os.Stat(credsCacheDir); err != nil {
		if err := runAWSCommand(); err != nil {
			return nil, fmt.Errorf("error executing AWS command: %w", err)
		}
	}

	var finalCreds *awsCreds
	err := filepath.Walk(credsCacheDir, func(path string, info fs.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}

		file, err := os.Open(path)
		if err != nil {
			return fmt.Errorf("error opening %q: %w", path, err)
		}
		defer file.Close()
		fileBytes, err := ioutil.ReadAll(file)
		if err != nil {
			return fmt.Errorf("error reading %q: %w", path, err)
		}

		var cacheInfo struct {
			Credentials awsCreds `json:"Credentials"`
		}
		err = json.Unmarshal(fileBytes, &cacheInfo)
		if err != nil {
			return fmt.Errorf("error unmarshalling %q: %w", path, err)
		}

		if cacheInfo.Credentials.Expiration.After(time.Now()) {
			finalCreds = &cacheInfo.Credentials
			return errDoneTraversing
		}
		return nil
	})
	if err == errDoneTraversing {
		return finalCreds, nil
	}
	if err != nil {
		return nil, fmt.Errorf("error traversing cache directory: %w", err)
	}
	return nil, nil
}

func runAWSCommand() error {
	return exec.Command("aws", "s3", "ls").Run()
}

func printCreds(creds *awsCreds) {
	fmt.Printf("export AWS_ACCESS_KEY=%s\n", creds.AccessKeyID)
	fmt.Printf("export AWS_SECRET_ACCESS_KEY=%s\n", creds.SecretAccessKey)
	fmt.Printf("export AWS_SESSION_TOKEN=%s\n", creds.SessionToken)
}
