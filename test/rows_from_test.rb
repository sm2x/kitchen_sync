require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

class RowsFromTest < KitchenSync::EndpointTestCase
  include TestTableSchemas

  def from_or_to
    :from
  end

  def insert_some_data
    execute "INSERT INTO footbl VALUES (1, 10, 'test'), (3, NULL, 'foo'), (4, NULL, NULL), (8, -1, 'longer str')"
  end

  def send_rows_command(*args)
    # rather than return a single array containing all the requested rows, which would mean the rows would
    # have to be buffered and counted before sending them, the rows command returns multiple packed objects,
    # terminating the resultset with a nil object (which is unambiguous since the rows are returned as arrays).
    rows = []
    result = send_command("rows", *args)
    while result
      rows << result
      result = unpacker.read
    end
    rows
  end

  test_each "returns an empty array if there are no such rows" do
    create_some_tables
    send_protocol_command

    assert_equal([], send_rows_command("footbl", ["0"], ["0"]))
    assert_equal([], send_rows_command("footbl", ["-1"], ["0"]))
    assert_equal([], send_rows_command("footbl", ["10"], ["11"]))
    assert_equal([], send_rows_command("secondtbl", ["0", "0"], ["0", "0"]))
  end

  test_each "returns the given data if requested" do
    create_some_tables
    insert_some_data
    send_protocol_command

    assert_equal([["1", "10", "test"      ]], send_rows_command("footbl", ["1"], ["1"]))
    assert_equal([["1", "10", "test"      ]], send_rows_command("footbl", ["1"], ["1"])) # same request
    assert_equal([["1", "10", "test"      ]], send_rows_command("footbl", ["0"], ["1"])) # different request, but same data matched
    assert_equal([["1", "10", "test"      ]], send_rows_command("footbl", ["1"], ["2"])) # ibid

    assert_equal([["3",  nil, "foo"       ]], send_rows_command("footbl", ["3"], ["3"])) # null numbers
    assert_equal([["4",  nil, nil         ]], send_rows_command("footbl", ["4"], ["4"])) # null strings
    assert_equal([["8", "-1", "longer str"]], send_rows_command("footbl", ["5"], ["9"])) # negative numbers

    assert_equal([["1", "10", "test"      ],
                  ["3",  nil, "foo"       ],
                  ["4",  nil, nil         ],
                  ["8", "-1", "longer str"]],
                 send_rows_command("footbl", ["0"], ["10"]))
  end
end