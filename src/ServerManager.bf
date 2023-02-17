using System;
using System.IO;
using System.Collections;

using Cacti.Json;

namespace Meteorite;

class Server {
	public String name = new .() ~ delete _;
	public String address = new .() ~ delete _;

	public Json ToJson() {
		Json json = .Object();

		json["name"] = .String(name);
		json["address"] = .String(address);

		return json;
	}

	public void FromJson(Json json) {
		name.Set(json["name"].AsString);
		address.Set(json["address"].AsString);
	}
}

class ServerManager : IEnumerable<Server> {
	private List<Server> servers = new .() ~ DeleteContainerAndItems!(_);

	public bool IsEmpty => servers.IsEmpty;

	public this() {
		// Open file and add a default localhost server if the file is not found
		FileStream fs = scope .();

		if (fs.Open("run/servers.json") case .Err(let err)) {
			fs.Close();

			if (err == .NotFound) {
				Server server = new .();

				server.name.Set("Localhost");
				server.address.Set("localhost");

				Add(server);
			}

			return;
		}

		// Parse json
		Json json;
		defer fs.Close();

		switch (JsonParser.Parse(fs)) {
		case .Ok(let val):	json = val;
		case .Err:			return;
		}

		defer json.Dispose();

		// Load servers
		for (let element in json.AsArray) {
			Server server = new .();
			server.FromJson(element);

			servers.Add(server);
		}
	}

	public void Add(Server server) {
		if (server.name.IsWhiteSpace || server.address.IsWhiteSpace) {
			delete server;
		}
		else {
			servers.Add(server);
			Save();
		}
	}

	public void MoveUp(Server server) {
		if (servers.Count < 2) return;

		int i = servers.IndexOf(server);
		if (i == -1 || i == 0) return;

		Server temp = servers[i - 1];
		servers[i - 1] = server;
		servers[i] = temp;

		Save();
	}

	public void MoveDown(Server server) {
		if (servers.Count < 2) return;

		int i = servers.IndexOf(server);
		if (i == -1 || i == servers.Count - 1) return;

		Server temp = servers[i + 1];
		servers[i + 1] = server;
		servers[i] = temp;

		Save();
	}

	public void Remove(Server server) {
		if (servers.Remove(server)) {
			Save();
		}

		delete server;
	}

	public List<Server>.Enumerator GetEnumerator() => servers.GetEnumerator();

	private void Save() {
		Json json = .Array();
		defer json.Dispose();

		for (Server server in servers) {
			json.Add(server.ToJson());
		}

		String data = JsonWriter.Write(json, .. scope .(), true);
		File.WriteAllText("run/servers.json", data);
	}
}