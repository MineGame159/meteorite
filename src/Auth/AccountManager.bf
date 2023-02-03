using System;
using System.IO;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite;

class AccountManager : IEnumerable<Account> {
	public List<Account> accounts = new .() ~ DeleteContainerAndItems!(_);
	public Account active;

	public this() {
		// Load accounts
		FileStream fs = scope .();
		if (fs.Open("run/accounts.json") case .Err) return;

		Json json;
		switch (JsonParser.Parse(fs)) {
		case .Ok(let val):	json = val;
		case .Err:			return;
		}
		defer json.Dispose();

		fs.Close();

		for (let accountJson in json.AsArray) {
			AccountType type = Enum.Parse<AccountType>(accountJson["type"].AsString);

			Account account = type.Load(accountJson);
			accounts.Add(account);

			if (accountJson["active"].AsBool) {
				active = account;
			}
		}

		// Add a default cracked account if the list is empty {
		if (IsEmpty) {
			accounts.Add(new CrackedAccount("Meteorite"));
		}

		// Authenticate into active account
		if (active.Authenticate() == .Err) {
			Log.Error("Failed to authenticate into account with username '{}'", active.username);
			Delete(active);
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

			Delete(active);
		}

		// Save
		Save();
	}

	public void Delete(Account account) {
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
		Json json = .Array();
		defer json.Dispose();

		for (Account account in accounts) {
			Json accountJson = account.ToJson();

			accountJson["active"] = .Bool(account == active);

			json.Add(accountJson);
		}

		String data = JsonWriter.Write(json, .. scope .(), true);
		File.WriteAllText("run/accounts.json", data);
	}

	public bool IsEmpty => accounts.IsEmpty;

	public List<Account>.Enumerator GetEnumerator() => accounts.GetEnumerator();
}