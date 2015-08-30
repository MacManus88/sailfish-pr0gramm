.pragma library

function api_request(api, callback){
    var url = "http://pr0gramm.com/" + api
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function(){
        if (xhr.readyState === XMLHttpRequest.DONE){
            var json = JSON.parse(xhr.responseText.toString())
            callback(json)
        }
    }
    xhr.open("GET", url);
    xhr.send();
}
