using System;
using System.Collections;

namespace Cacti;

class SinglyLinkedList<T> : IEnumerable<T> {
	struct Node<T> {
		public Node<T>* next;
		public T value;
	}

	private IRawAllocator alloc;

	private Node<T>* first, last;
	private int count;

	public int Count => count;

	public this(IRawAllocator alloc = null) {
		this.alloc = alloc;
	}

	public ~this() {
		Node<T>* node = first;

		while (node != null) {
			Node<T>* toFree = node;
			node = node.next;
			
			Free(toFree);
		}
	}

	public void Add(T item) {
		Node<T>* node = Alloc();

		node.value = item;
		count++;

		if (last != null) {
			last.next = node;
			last = node;
		}
		else {
			first = node;
			last = node;
		}
	}

	public Enumerator GetEnumerator() => .(first);

	private Node<T>* Alloc() {
		if (alloc != null) return (.) alloc.Alloc(sizeof(Node<T>), alignof(Node<T>));
		return new .();
	}

	private void Free(Node<T>* node) {
		if (alloc != null) alloc.Free(node);
		else delete node;
	}

	public struct Enumerator : IEnumerator<T> {
		private Node<T>* node;
		private int i = -1;

		public int Index => i;

		public this(Node<T>* node) {
			this.node = node;
		}

		public Result<T> GetNext() mut {
			if (node == null) return .Err;

			Node<T>* toReturn = node;
			node = node.next;

			i++;
			return toReturn.value;
		}
	}
}