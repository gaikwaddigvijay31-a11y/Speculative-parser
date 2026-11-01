
`timescale 1ns/1ps

module tb_order_book;

    import fixed_point_pkg::*;

    logic clk;
    logic rst_n;
    logic enable;

    parsed_msg_t msg_in;
    logic msg_valid;

    top_of_book_t tob;
    logic tob_valid;

    logic [7:0] bid_depth;
    logic [7:0] ask_depth;

    integer tests_passed;
    integer tests_failed;

    order_book dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .msg_in(msg_in),
        .msg_valid(msg_valid),
        .tob(tob),
        .tob_valid(tob_valid),
        .bid_depth(bid_depth),
        .ask_depth(ask_depth)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic send_message(input parsed_msg_t message);
        begin
            @(negedge clk);
            msg_in = message;
            msg_valid = 1'b1;

            @(negedge clk);
            msg_valid = 1'b0;
            msg_in = '0;

            repeat (2) @(negedge clk);
        end
    endtask

    task automatic check_result(
        input logic condition,
        input string test_name
    );
        begin
            if (condition) begin
                $display("PASS: %s", test_name);
                tests_passed = tests_passed + 1;
            end
            else begin
                $display("FAIL: %s", test_name);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    initial begin

        $dumpfile("order_book.vcd");
        $dumpvars(0, tb_order_book);

        rst_n = 0;
        enable = 0;
        msg_valid = 0;
        msg_in = '0;

        tests_passed = 0;
        tests_failed = 0;

        repeat (3) @(negedge clk);

        rst_n = 1;
        enable = 1;

        repeat (2) @(negedge clk);

        $display("================================");
        $display("ORDER BOOK TESTBENCH");
        $display("================================");

        msg_in = '0;
        msg_in.valid = 1'b1;
        msg_in.msg_type = MSG_ADD;
        msg_in.order_id = 64'd1;
        msg_in.price = 32'd100;
        msg_in.quantity = 32'd10;
        msg_in.side = SIDE_BID;

        send_message(msg_in);

        check_result(
            tob_valid === 1'b0,
            "ADD first bid order"
        );

        msg_in = '0;
        msg_in.valid = 1'b1;
        msg_in.msg_type = MSG_ADD;
        msg_in.order_id = 64'd2;
        msg_in.price = 32'd110;
        msg_in.quantity = 32'd12;
        msg_in.side = SIDE_ASK;

        send_message(msg_in);

        check_result(
            tob_valid === 1'b1,
            "ADD ask order and generate top of book"
        );

        check_result(
            tob.best_bid === 32'd100,
            "Best bid price"
        );

        check_result(
            tob.best_ask === 32'd110,
            "Best ask price"
        );

        check_result(
            tob.bid_qty === 32'd10,
            "Best bid quantity"
        );

        check_result(
            tob.ask_qty === 32'd12,
            "Best ask quantity"
        );

        msg_in = '0;
        msg_in.valid = 1'b1;
        msg_in.msg_type = MSG_ADD;
        msg_in.order_id = 64'd3;
        msg_in.price = 32'd100;
        msg_in.quantity = 32'd5;
        msg_in.side = SIDE_BID;

        send_message(msg_in);

        check_result(
            tob.bid_qty === 32'd15,
            "Aggregate bid quantity"
        );

        msg_in = '0;
        msg_in.valid = 1'b1;
        msg_in.msg_type = MSG_EXECUTE;
        msg_in.order_id = 64'd1;
        msg_in.quantity = 32'd4;

        send_message(msg_in);

        check_result(
            tob.bid_qty === 32'd11,
            "Execute order and reduce bid quantity"
        );

        msg_in = '0;
        msg_in.valid = 1'b1;
        msg_in.msg_type = MSG_DELETE;
        msg_in.order_id = 64'd3;

        send_message(msg_in);

        check_result(
            tob.bid_qty === 32'd6,
            "Delete order and update bid quantity"
        );

        check_result(
            bid_depth === 8'd1,
            "Bid depth"
        );

        check_result(
            ask_depth === 8'd1,
            "Ask depth"
        );

        $display("================================");
        $display("TEST SUMMARY");
        $display("================================");
        $display("Tests passed: %0d", tests_passed);
        $display("Tests failed: %0d", tests_failed);
        $display("================================");

        if (tests_failed == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED");

        #20;
        $finish;

    end

endmodule
