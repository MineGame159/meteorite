using System;
using System.IO;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite;

class Server {
	public String name = new .() ~ delete _;
	public String address = new .() ~ delete _;

	public void ToJson(JsonWriter json) {
		using (json.Object()) {
			json.String("name", name);
			json.String("address", address);
		}
	}

	public void FromJson(Json json) {
		name.Set(json["name"].AsString);
		address.Set(json["address"].AsString);
	}
}

class ServerManager : IEnumerable<Server> {
	private List<Server> servers = new .() ~ DeleteContainerAndItems!(_);

	public bool IsEmpty => servers.IsEmpty;
	
	[Tracy.Profile]
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
		JsonTree tree;
		defer fs.Close();

		switch (JsonParser.Parse(fs)) {
		case .Ok(let val):	tree = val;
		case .Err:			return;
		}

		defer delete tree;

		// Load servers
		for (let element in tree.root.AsArray) {
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
		FileStream fs = scope .();

		if (fs.Create("run/servers.json", .Write) case .Err) {
			Log.Error("Failed to save server list to 'run/servers.json'");
			return;
		}

		JsonWriter json = scope .(scope MyStreamWriter(fs), true);

		using (json.Array()) {
			for (Server server in servers) {
				server.ToJson(json);
			}
		}
	}
}