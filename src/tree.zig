const std = @import("std");
const DoublyLinkedList = std.DoublyLinkedList;
const ArrayList = std.ArrayList;
var default_allocator = std.heap.page_allocator;

pub fn Leaf(comptime T: type) type {
    return struct {
        elem: T,
        _parent: ?*Leaf(T),
        children: std.ArrayList(*Leaf(T)),
        tree: *Tree(T),

        fn init(tree: *Tree(T), value: T, parent: ?*Leaf(T)) !*Leaf(T) {
            const result = try tree.arenaAllocator.allocator().create(Leaf(T));
            result.elem = value;
            result._parent = parent;
            result.tree = tree;
            result.children = std.ArrayList(*Leaf(T)).init(tree.arenaAllocator.allocator());
            return result;
        }

        fn set_value(self: *Leaf(T), value: T) void {
            self.elem = value;
        }

        fn get_parent(self: *Leaf(T)) ?Leaf(T) {
            return self._parent;
        }
        
        pub fn add_child(self: *Leaf(T), value: T) !*Leaf(T) {
            const leaf = try Leaf(T).init(self.tree, value, self);
            try self.children.append(leaf);
            return leaf;
        }
    };
}

pub fn Tree(comptime T: type) type {
    return struct {
        root: *Leaf(T),
        arenaAllocator: std.heap.ArenaAllocator,

        pub fn init(value: T, arenaAllocator: *std.heap.ArenaAllocator) !*Tree(T) {
            var result = try arenaAllocator.allocator().create(Tree(T));
            result.arenaAllocator = arenaAllocator.*;
            result.root = try Leaf(T).init(result, value, null);
            return result;
        }
    };
}

test "create tree" {
    var arenaAllocator = std.heap.ArenaAllocator.init(default_allocator);
    const newTree = try Tree(u32).init(3, &arenaAllocator);
    try std.testing.expectEqual(3, newTree.root.elem);
}

test "add leaf to root" {
    var arenaAllocator = std.heap.ArenaAllocator.init(default_allocator);
    var newTree = try Tree(u32).init(5, &arenaAllocator);
    const result = try newTree.root.add_child(2);
    _ = result;
    const result2 = try newTree.root.add_child(4);
    _ = result2;
    try std.testing.expectEqual(2, newTree.root.children.items[0].elem);
    try std.testing.expectEqual(4, newTree.root.children.items[1].elem);
}
