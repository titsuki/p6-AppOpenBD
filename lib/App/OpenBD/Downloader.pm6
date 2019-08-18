unit class App::OpenBD::Downloader:ver<0.0.1>;

use v6;
use HTTP::Tinyish;
use JSON::Fast;

submethod BUILD {
}

method download-coverage(Str $filename = "coverage.json", $dir = ".p6openbd") {
    my $http = HTTP::Tinyish.new(agent => "Mozilla/4.0");
    my $url = "https://api.openbd.jp/v1/coverage";
    my %res = $http.get($url, :bin);
    my $fh = open($dir ~ "/" ~ $filename, :w);
    $fh.write: %res<content>;
}

method download-books(Str $filename = "coverage.json", $dir = ".p6openbd") {
    my @coverage = @(from-json(($dir ~ "/" ~ $filename).IO.slurp));
    my $http = HTTP::Tinyish.new(agent => "Mozilla/4.0");

    for @coverage.rotor(5000).pairs -> (:key($id), :value($batch)) {
        my $isbn-list = @($batch).join(",");
        my $url = "https://api.openbd.jp/v1/get?isbn=" ~ $isbn-list;
        my %res = $http.get($url, :bin);
        my $fh = open(sprintf("$dir/part-%05d", $id), :w);
        $fh.write: %res<content>;
    }
}
