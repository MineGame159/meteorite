using System;
using System.IO;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite;

class AccountManager : IEnumerable<Account> {
	public List<Account> accounts = new .() ~ DeleteContainerAndItems!(_);
	public Account active;
	
	[Tracy.Profile]
	public this() {
		// Open file and add a default cracked account if the file is not found
		FileStream fs = scope .();

		if (fs.Open("run/accounts.json") case .Err(let err)) {
			fs.Close();

			if (err == .NotFound) {
				Add(new CrackedAccount("Meteorite"));
			}

			return;
		}

		// Parse json
		JsonTree tree;
		defer fs.Close();

		switch (JsonParser.Parse(fs)) {
		case .Ok(let val):	tree = val;
		case .Err:			return;
		}

		defer delete tree;
		Json json = tree.root;
		
		// Load accounts
		for (let accountJson in json.AsArray) {
			AccountType type = Enum.Parse<AccountType>(accountJson["type"].AsString);

			Account account = type.Load(accountJson);
			accounts.Add(account);

			if (accountJson["active"].AsBool) {
				active = account;
			}
		}

		// Authenticate into active account
		if (active.Authenticate() == .Err) {
			Log.Error("Failed to authenticate into account with username '{}'", active.username);
			Remove(active);
		}
	}

	public void Add(Account account) {
		accounts.Add(account);
		if (active == null) active = account;

		// Save
		Save();
	}

	public void Select(Account account) {
		active = account;

		if (active.Authenticate() == .Err) {
			if (account.username.IsEmpty) Log.Error("Failed to authenticate into account");
			else Log.Error("Failed to authenticate into account with username '{}'", account.username);

			Remove(active);
		}

		// Save
		Save();
	}

	public void Remove(Account account) {
		// Delete account
		accounts.Remove(account);
		if (account == active) active = null;

		delete account;

		// Set new active account if there are some left
		if (!accounts.IsEmpty) {
			Select(accounts[0]);
		}

		// Save
		Save();
	}

	public void Save() {
		FileStream fs = scope .();

		if (fs.Create("run/accounts.json", .Write) case .Err) {
			Log.Error("Failed to save account list to 'run/accounts.json'");
			return;
		}

		JsonWriter json = scope .(scope MyStreamWriter(fs), true);

		using (json.Array()) {
			for (Account account in accounts) {
				account.ToJson(account == active, json);
			}
		}
	}

	public bool IsEmpty => accounts.IsEmpty;

	public List<Account>.Enumerator GetEnumerator() => accounts.GetEnumerator();
}