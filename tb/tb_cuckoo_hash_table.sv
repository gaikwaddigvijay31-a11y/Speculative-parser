
`timescale 1ns/1ps

module tb_cuckoo_hash_table;

    import fixed_point_pkg::*;

    logic clk;
    logic rst_n;

    // Lookup interface
    order_id_t lookup_key;
    logic lookup_valid;
    logic lookup_hit;
    price_t lookup_price;
    qty_t lookup_qty;
    side_t lookup_side;
    logic lookup_done;

    // Insert interface
    order_id_t insert_key;
    price_t insert_price;
    qty_t insert_qty;
    side_t insert_side;
    logic insert_valid;
    logic insert_done;
    logic insert_fail;

    // Delete interface
    order_id_t delete_key;
    logic delete_valid;
    logic delete_done;
    logic delete_hit;

    // Update interface
    order_id_t update_key;
    qty_t update_new_qty;
    logic update_valid;
    logic update_done;

    // Status
    logic [31:0] entry_count;
    logic table_full;

    integer tests_passed;
    integer tests_failed;

    logic result_hit;
    price_t result_price;
    qty_t result_qty;
    side_t result_side;

    // DUT
    cuckoo_hash_table dut (
        .clk(clk),
        .rst_n(rst_n),

        .lookup_key(lookup_key),
        .lookup_valid(lookup_valid),
        .lookup_hit(lookup_hit),
        .lookup_price(lookup_price),
        .lookup_qty(lookup_qty),
        .lookup_side(lookup_side),
        .lookup_done(lookup_done),

        .insert_key(insert_key),
        .insert_price(insert_price),
        .insert_qty(insert_qty),
        .insert_side(insert_side),
        .insert_valid(insert_valid),
        .insert_done(insert_done),
        .insert_fail(insert_fail),

        .delete_key(delete_key),
        .delete_valid(delete_valid),
        .delete_done(delete_done),
        .delete_hit(delete_hit),

        .update_key(update_key),
        .update_new_qty(update_new_qty),
        .update_valid(update_valid),
        .update_done(update_done),

        .entry_count(entry_count),
        .table_full(table_full)
    );

    // Clock: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;


    // --------------------------------
    // INSERT TASK
    // --------------------------------

    task automatic insert_order(
        input order_id_t key,
        input price_t price,
        input qty_t quantity,
        input side_t side
    );
        begin
            @(negedge clk);

            insert_key = key;
            insert_price = price;
            insert_qty = quantity;
            insert_side = side;
            insert_valid = 1'b1;

            wait(insert_done === 1'b1);

            @(negedge clk);
insert_valid = 1'b0;

@(posedge clk);
#1;
        end
    endtask


    // --------------------------------
    // LOOKUP TASK
    // --------------------------------

    task automatic lookup_order(
        input order_id_t key
    );
        begin
            @(negedge clk);

            lookup_key = key;
            lookup_valid = 1'b1;

            wait(lookup_done === 1'b1);

            result_hit = lookup_hit;
            result_price = lookup_price;
            result_qty = lookup_qty;
            result_side = lookup_side;

            @(negedge clk);
            lookup_valid = 1'b0;
        end
    endtask


    // --------------------------------
    // DELETE TASK
    // --------------------------------

    task automatic delete_order(
        input order_id_t key
    );
        begin
            @(negedge clk);

            delete_key = key;
            delete_valid = 1'b1;

            wait(delete_done === 1'b1);

            @(negedge clk);
            delete_valid = 1'b0;
        end
    endtask


    // --------------------------------
    // UPDATE TASK
    // --------------------------------

    task automatic update_order(
        input order_id_t key,
        input qty_t new_quantity
    );
        begin
            @(negedge clk);

            update_key = key;
            update_new_qty = new_quantity;
            update_valid = 1'b1;

            wait(update_done === 1'b1);

            @(negedge clk);
            update_valid = 1'b0;
        end
    endtask


    // --------------------------------
    // CHECK TASK
    // --------------------------------

    task automatic check_result(
        input logic condition,
        input string test_name
    );
        begin
            if (condition === 1'b1) begin
                $display("PASS: %s", test_name);
                tests_passed = tests_passed + 1;
            end
            else begin
                $display("FAIL: %s", test_name);
                tests_failed = tests_failed + 1;
            end
        end
    endtask


    // --------------------------------
    // MAIN TEST SEQUENCE
    // --------------------------------

    initial begin

        $dumpfile("cuckoo_hash_table.vcd");
        $dumpvars(0, tb_cuckoo_hash_table);

        // Initialize inputs
        rst_n = 0;

        lookup_key = '0;
        lookup_valid = 0;

        insert_key = '0;
        insert_price = '0;
        insert_qty = '0;
        insert_side = SIDE_BID;
        insert_valid = 0;

        delete_key = '0;
        delete_valid = 0;

        update_key = '0;
        update_new_qty = '0;
        update_valid = 0;

        tests_passed = 0;
        tests_failed = 0;

        result_hit = 0;
        result_price = '0;
        result_qty = '0;
        result_side = '0;

        // Reset
        repeat (3) @(negedge clk);

        rst_n = 1;

        repeat (2) @(negedge clk);

        $display("====================================");
        $display("CUCKOO HASH TABLE TESTBENCH");
        $display("====================================");

        // TEST 1: Reset and entry count

        check_result(
            entry_count === 32'd0,
            "Reset entry count"
        );

        check_result(
            table_full === 1'b0,
            "Table not full after reset"
        );


        // TEST 2: Insert first order

        insert_order(
            64'd1,
            32'd100,
            32'd10,
            SIDE_BID
        );

        check_result(
            insert_done === 1'b0,
            "Insert completion pulse cleared"
        );

        check_result(
            insert_fail === 1'b0,
            "First insertion succeeds"
        );

        check_result(
            entry_count === 32'd1,
            "Entry count after first insertion"
        );


        // TEST 3: Lookup existing order

        lookup_order(64'd1);

        check_result(
            result_hit === 1'b1,
            "Lookup existing order"
        );

        check_result(
            result_price === 32'd100,
            "Lookup correct price"
        );

        check_result(
            result_qty === 32'd10,
            "Lookup correct quantity"
        );

        check_result(
            result_side === SIDE_BID,
            "Lookup correct side"
        );


        // TEST 4: Insert second order

        insert_order(
            64'd2,
            32'd110,
            32'd20,
            SIDE_ASK
        );

        check_result(
            insert_fail === 1'b0,
            "Second insertion succeeds"
        );

        check_result(
            entry_count === 32'd2,
            "Entry count after second insertion"
        );


        // TEST 5: Lookup second order

        lookup_order(64'd2);

        check_result(
            result_hit === 1'b1,
            "Lookup second order"
        );

        check_result(
            result_price === 32'd110,
            "Second order price"
        );

        check_result(
            result_qty === 32'd20,
            "Second order quantity"
        );

        check_result(
            result_side === SIDE_ASK,
            "Second order side"
        );


        // TEST 6: Update quantity

        update_order(
            64'd1,
            32'd6
        );

        lookup_order(64'd1);

        check_result(
            result_hit === 1'b1,
            "Order exists after update"
        );

        check_result(
            result_qty === 32'd6,
            "Partial fill quantity update"
        );


        // TEST 7: Delete existing order

        delete_order(64'd1);

        check_result(
            delete_hit === 1'b1,
            "Delete existing order"
        );

        check_result(
            entry_count === 32'd1,
            "Entry count after deletion"
        );


        // TEST 8: Verify deleted order

        lookup_order(64'd1);

        check_result(
            result_hit === 1'b0,
            "Deleted order lookup returns miss"
        );


        // TEST 9: Lookup nonexistent order

        lookup_order(64'd999);

        check_result(
            result_hit === 1'b0,
            "Nonexistent order lookup returns miss"
        );


        // TEST 10: Delete nonexistent order

        delete_order(64'd999);

        check_result(
            delete_hit === 1'b0,
            "Deleting nonexistent order returns miss"
        );

        check_result(
            entry_count === 32'd1,
            "Entry count unchanged after failed deletion"
        );


        // Final summary

        $display("====================================");
        $display("TEST SUMMARY");
        $display("====================================");

        $display("Tests passed: %0d", tests_passed);
        $display("Tests failed: %0d", tests_failed);

        $display("====================================");

        if (tests_failed == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED");

        #20;
        $finish;

    end

endmodule
