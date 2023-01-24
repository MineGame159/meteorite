using System;
using System.Collections;

namespace Cacti;

public struct LineEnumerator : IEnumerator<StringView> {
	private StringSplitEnumerator enumerator;

	public this(StringSplitEnumerator enumerator) {
		this.enumerator = enumerator;
	}

	public bool HasMore => enumerator.HasMore;
	public int Index => enumerator.MatchIndex;
	public int Position => enumerator.MatchPos;

	public Result<StringView> GetNext() mut {
		switch (enumerator.GetNext()) {
		case .Ok(let val): return val.EndsWith('\r') ? val[...^2] : val;
		case .Err:         return .Err;
		}
	}
}