const std = @import("std");
const Tree = @import("tree.zig").Tree;
const Leaf = @import("tree.zig").Leaf;

var default_allocator = std.heap.page_allocator;

pub const ValueItem = struct {
    amount: u32,
    cost: u32
};

const Sum = struct {
    index: usize = 0,
    amount: u32 = 0,
    cost: u32 = 0,
};

const ResultHolder = struct {
    leaf_pointer: *Leaf(Sum)
};

fn valueItemCompare(void_val: void, lhs: ValueItem, rhs: ValueItem) bool {
    _ = void_val;
    if (lhs.amount < rhs.amount) {
        return true;
    } else if (lhs.amount > rhs.amount) {
        return false;
    } else {
        return lhs.cost < rhs.cost;
    }
}

pub fn get_cheapest_value(value_items: []const ValueItem, min_items: u32, allocator: std.mem.Allocator) ![]ValueItem {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena_allocator_allocator = arena_allocator.allocator();
    defer arena_allocator.deinit();
    var smaller = std.ArrayList(ValueItem).init(arena_allocator_allocator);
    var bigger = std.ArrayList(ValueItem).init(arena_allocator_allocator);
    for (value_items) |item| {
        if (item.amount < min_items) {
            try smaller.append(item);
        } else {
            try bigger.append(item);
        }
    }

    var total_smaller_items: u32 = 0;
    for (smaller.items) |item| {
        total_smaller_items += item.amount;
    }

    if (bigger.items.len == 0) {
        // Use all items
        if (total_smaller_items == min_items) {
            return try default_allocator.dupe(ValueItem, value_items);
        }

        // No solution
        if (total_smaller_items < min_items) {
            return try default_allocator.alloc(ValueItem, 0);
        }
    }

    var cheapest = ValueItem{
        .amount = 0,
        .cost = 2147483647
    };

    for (bigger.items) |item| {
        if (item.cost < cheapest.cost) {
            cheapest = item;
        }
    }

    if (total_smaller_items < min_items) {
        // Optimal solution is the cheapest group with enough items
        var result = try default_allocator.alloc(ValueItem, 1);
        result[0] = cheapest;
        return result;
    }

    std.mem.sort(ValueItem, smaller.items, {}, valueItemCompare);

    var to_beat: u32 = cheapest.cost;
    const tree = try Tree(Sum).init(.{.amount = 0, .cost = 0, .index = smaller.items.len}, &arena_allocator, smaller.items.len);
    var result_holder = ResultHolder{.leaf_pointer = tree.root};
    try calculate_best_sum(smaller.items, tree.root, &to_beat, &result_holder, min_items);
    var result = std.ArrayList(ValueItem).init(arena_allocator_allocator);
    var current_leaf_pointer = result_holder.leaf_pointer;
    var tempList = std.ArrayList(Sum).init(default_allocator);
    defer tempList.clearAndFree();

    while (current_leaf_pointer._parent != null) {
        try tempList.append(current_leaf_pointer.elem);
        current_leaf_pointer = current_leaf_pointer._parent.?;
    }

    for (tempList.items) |elem| {
        try result.append(smaller.items[elem.index]);
    }

    return allocator.dupe(ValueItem, result.items);

}

fn calculate_best_sum(list: []ValueItem, leaf: *Leaf(Sum), to_beat: *u32, best_leaf: *ResultHolder, min_items: u32) !void {
    var i = leaf.elem.index;
    while (i >= 1): (i -= 1) {
        const index = i - 1;
        var current_sum = leaf.elem;
        current_sum.index = index;
        const current = list[index];
        current_sum.amount += current.amount;
        current_sum.cost += current.cost;
        const new_leaf = try leaf.add_child(current_sum);
        if (current_sum.amount >= min_items) {
            if (current_sum.cost < to_beat.*) {
                to_beat.* = current_sum.cost;
                best_leaf.leaf_pointer = new_leaf;
            }
        } else {
            if (current_sum.cost < to_beat.*) {
                try calculate_best_sum(list, new_leaf, to_beat, best_leaf,min_items);
            }
        }
    }
}

test "simple test" {
    const val = ValueItem{
        .amount = 3,
        .cost = 4
    };
    const val_arr = [_]ValueItem{val, .{.amount = 2, .cost = 3}};
    const result = try get_cheapest_value(val_arr[0..], 2, default_allocator);
    std.debug.print("{any}\n", .{result});
}

test "simple test 2" {
    const val = ValueItem{
        .amount = 3,
        .cost = 4
    };
    const val_arr = [_]ValueItem{val, .{.amount = 2, .cost = 3}};
    const result = try get_cheapest_value(val_arr[0..], 4, default_allocator);
    std.debug.print("Result: {any}\n", .{result});
}

test "complicated test" {
    const val_arr = [_]ValueItem{.{.amount = 2, .cost = 3},.{.amount = 2, .cost = 3},.{.amount = 2, .cost = 3},.{.amount = 2, .cost = 3},.{.amount = 5, .cost = 12},.{.amount = 2, .cost = 3},};
    const result = try get_cheapest_value(val_arr[0..], 7, default_allocator);
    std.debug.print("Result: {any}\n", .{result});
}