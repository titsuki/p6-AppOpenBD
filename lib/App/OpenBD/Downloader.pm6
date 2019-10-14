use v6;
use LibCurl::HTTP;
use JSON::Fast;

unit class App::OpenBD::Downloader:ver<0.0.1>;

submethod BUILD {
}

method download-coverage(Str $filename = "coverage.json", $dir = "$*HOME/.p6openbd") {
    my $http = LibCurl::HTTP.new;
    my $url = "https://api.openbd.jp/v1/coverage";
    my $resp = $http.GET($url).perform;
    my $fh = open("$dir/$filename", :w);
    $fh.print: $resp.content;
    LEAVE $fh.close;
}

method download-books(Str $filename = "coverage.json", $dir = "$*HOME/.p6openbd") {
    my @coverage = @(from-json(($dir ~ "/" ~ $filename).IO.slurp));

    my &converter = -> (:key($id), :value($batch)) {
        my $isbn-list = "isbn=" ~ @($batch).join(",");
        %(:$id, :content($isbn-list));
    };

    my &process = -> %query {
        my $http = LibCurl::HTTP.new;
        my $resp = $http.POST("https://api.openbd.jp/v1/get", %query<content>).perform;
        my $fh = open(sprintf("$dir/part-%05d", %query<id>), :w);
        $fh.print: $resp.content;
        $fh.close if $fh;
    };

    @coverage.rotor(5000).pairs.map(&converter).race.map(&process);
}
