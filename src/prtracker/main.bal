import ballerina/config;
import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;

http:Client clientEndpoint = new("https://api.github.com/");
public function main() {
    http:Request request = new();
    string githubToken = config:getAsString("github.token");
    string GITHUB_API_TOKEN="";
    request.addHeader("Authorization", "bearer " + GITHUB_API_TOKEN);
    json payload = {
        "query": "
            {
                repository(owner: \"ballerina-platform\", name: \"ballerina-lang\") {
                    name
                    pullRequests(states: OPEN, baseRefName: \"master\", first: 100, orderBy: {field: CREATED_AT, direction: DESC}) {
                    nodes {
                        url
                        suggestedReviewers {
                        reviewer {
                            login
                        }
                        }
                        title
                        author {
                        login
                        }
                        createdAt
                    }
                    }
                }
            }
        "
    };
    request.setJsonPayload(payload);

    var response = clientEndpoint->post("/graphql", request);
    if (response is http:Response) {
        var msg = response.getJsonPayload();
        map<json> msgMap = <map<json>> msg;
        if (msg is json) {
            if (msg.data.repository.pullRequests.nodes is json[]) {
                json[] prList = <json[]> msg.data.repository.pullRequests.nodes;
                int i = 0;
                while (i < prList.length()) {
                    var createdAt = time:parse(prList[i].createdAt.toString(), "yyyy-MM-dd'T'HH:mm:ss'Z'");
                    if (createdAt is time:Time) {
                        var yesterDay = time:subtractDuration(time:currentTime(), 0, 0, 1, 0, 0, 0, 0);
                        if (yesterDay.time > createdAt.time) {
                            io:println(prList[i]);
                        }
                    }
                    i = i + 1;
                }
            }
        } else {
            io:println("Invalid payload received:" , msg.reason());
        }
    } else {
        io:println(response.reason());
    }
}