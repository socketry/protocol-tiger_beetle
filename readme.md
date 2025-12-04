# Protocol::TigerBeetle

A (very incomplete, but sufficient for benchmarking) TigerBeetle protocol implementation for Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "protocol-tiger_beetle"
```

You will also need `libaegis` and `tigerbeetle`.


## Usage

```bash
> bundle exec ruby ./test.rb 8
/home/samuel/Developer/socketry/protocol-tiger_beetle/lib/protocol/tiger_beetle/connection.rb:19: warning: IO::Buffer is experimental and both the Ruby and C interface may change in the future!
Registered! Session: 1331
Benchmarking with batches of 8 transfers for ~5.0s...

Results:
  Batches sent: 661
  Total transfers: 5288
  Elapsed time: 5.004s
  Rate: 1057 transfers/second
```

### Results

I performed these benchmarks on a Linux machine with an AMD Ryzen 9950X3D CPU.

| Batch Size | Batches Sent | Elapsed Time (s) | Rate (transfers/s) | User Time (s) | System Time (s) |
|------------|--------------|------------------|--------------------|---------------|-----------------|
| 1          | 653          | 5.003            | 131                | 0.150         | 0.019           |
| 2          | 603          | 5.001            | 241                | 0.146         | 0.018           |
| 4          | 621          | 5.008            | 496                | 0.153         | 0.022           |
| 8          | 600          | 5.005            | 959                | 0.165         | 0.014           |
| 16         | 660          | 5.003            | 2,111              | 0.178         | 0.024           |
| 32         | 643          | 5.001            | 4,115              | 0.211         | 0.030           |
| 64         | 643          | 5.000            | 8,230              | 0.284         | 0.029           |
| 128        | 630          | 5.005            | 16,111             | 0.430         | 0.021           |
| 256        | 620          | 5.006            | 31,704             | 0.632         | 0.030           |
| 512        | 637          | 5.001            | 65,211             | 1.008         | 0.028           |
| 1024       | 470          | 5.009            | 96,080             | 1.354         | 0.032           |
| 2048       | 293          | 5.014            | 119,669            | 2.192         | 0.024           |
| 4096       | 184          | 5.009            | 150,476            | 2.489         | 0.027           |
| 8192       | 209          | 5.016            | 341,353            | 5.107         | 0.020           |
| 16384      | 101          | 5.020            | 329,663            | 5.116         | 0.019           |

During these benchmarks, the TigerBeetle CPU usage was monitored and remained below 10% of one CPU core at all times. However, I noticed that the utilization on my SSD was high, so it appears to be the main bottleneck:

```
avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           1.00    0.00    0.09    3.13    0.00   95.78

Device            r/s     rMB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wMB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dMB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
nvme0n1          0.00      0.00     0.00   0.00    0.00     0.00  428.00     18.37    59.00  12.11    2.84    43.94    0.00      0.00     0.00   0.00    0.00     0.00   13.00    2.23    1.24  74.70
nvme1n1          0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00


avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           1.10    0.00    0.25    3.32    0.00   95.34

Device            r/s     rMB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wMB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dMB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
nvme0n1          0.00      0.00     0.00   0.00    0.00     0.00  461.00     22.04   105.00  18.55    2.69    48.96    0.00      0.00     0.00   0.00    0.00     0.00   21.00    2.48    1.29  76.00
nvme1n1          0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
```

(These are some notable samples).

#### Observations

- Transfer rate increases dramatically with larger batch sizes, peaking at 341,353 transfers/s with batch size 8192.
- Ruby CPU time increases with batch sizes, and Ruby becomes the bottleneck around 8192 transactions per batch, with a total throughput of 340k transfers/s.
- At small batch sizes, the TigerBeetle CPU usage was < 4% of one CPU core and at higher batch sizes remained under 10% most of the time.
- System CPU time remains relatively stable across all batch sizes (0.014-0.032s) - in other words, actual network overhead is minimal.
- For small batch sizes, say less than 512, Ruby is waiting for TigerBeetle to process requests and is idle for 80%+ of the time.
- It looks like TigerBeetle can handle at most ~650 batches per second irrespective of batch size and is primarily limited by disk I/O sync operations.

#### Opinions

- TigerBeetle does not feel fast enough to be used for a lot of small discrete transactions. It's performance really only looks acceptable when batching hundreds or thousands of transactions together.
- Ruby's performance is good enough to keep up with TigerBeetle up to batch sizes of 8192 transactions. Beyond that, Ruby saturates one CPU core.
- While developing this code, I switched between the official released version of TigerBeetle (0.16.66) and the latest commit on GitHub. The database files were incompatible with no obvious option for migration.
- The performance on macOS was about half of that on Linux.
- The protocol was not that straight forward to implement. I had to refer to the source code and there was no "official" protocol documentation or standard that I could find.
