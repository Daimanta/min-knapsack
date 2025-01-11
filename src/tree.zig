const std = @import("std");
const DoublyLinkedList = std.DoublyLinkedList;
const ArrayList = std.ArrayList;
var default_allocator = std.heap.page_allocator;

pub fn Leaf(comptime T: type) type {
    return struct {
        elem: T,
        _parent: ?*Leaf(T),
        children: []*Leaf(T),
        number_of_children: usize = 0,
        tree: *Tree(T),

        fn init(tree: *Tree(T), value: T, parent: ?*Leaf(T)) !*Leaf(T) {
            const result = try tree.arenaAllocator.allocator().create(Leaf(T));
            result.elem = value;
            result._parent = parent;
            result.tree = tree;
            result.number_of_children = 0;
            result.children = try tree.arenaAllocator.allocator().alloc(*Leaf(T), tree.max_children);

            return result;
        }

        fn set_value(self: *Leaf(T), value: T) void {
            self.elem = value;
        }

        fn get_parent(self: *Leaf(T)) ?Leaf(T) {
            return self._parent;
        }
        
        pub fn add_child(self: *Leaf(T), value: T) !*Leaf(T) {
            if (self.number_of_children < self.tree.max_children) {
                const leaf = try Leaf(T).init(self.tree, value, self);
                self.children[self.number_of_children] = leaf;
                self.number_of_children += 1;
                return self.children[self.number_of_children - 1];
            } else {
                return error.TooManyChildren;
            }
        }
    };
}

pub fn Tree(comptime T: type) type {
    return struct {
        root: *Leaf(T),
        arenaAllocator: std.heap.ArenaAllocator,
        max_children: usize,

        pub fn init(value: T, arenaAllocator: *std.heap.ArenaAllocator, max_children: usize) !*Tree(T) {
            var result = try arenaAllocator.allocator().create(Tree(T));
            result.arenaAllocator = arenaAllocator.*;
            result.max_children = max_children;
            result.root = try Leaf(T).init(result, value, null);
            return result;
        }
    };
}

test "create tree" {
    var arenaAllocator = std.heap.ArenaAllocator.init(default_allocator);
    const newTree = try Tree(u32).init(3, &arenaAllocator,3);
    std.debug.print("{d}\n", .{newTree.root.elem});
}

test "add leaf to root" {
    var arenaAllocator = std.heap.ArenaAllocator.init(default_allocator);
    var newTree = try Tree(u32).init(5, &arenaAllocator,3);
    const result = try newTree.root.add_child(2);
    const result2 = try newTree.root.add_child(4);
    std.debug.print("{d} {d}\n", .{result.elem, result2.elem});
}
