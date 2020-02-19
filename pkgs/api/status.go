package api

import (
	"net/http"

	"github.com/go-chi/chi"
	"github.com/go-chi/render"
)

type StatusResponse struct {
	Status	bool	`json:"Healthy"`
	Message	string	`json:"Message"`
}

func StatusRoutes() *chi.Mux {
	router := chi.NewRouter()
	router.Get("/", GetAllHealth)
	router.Get("/api", GetApiHealth)
	router.Get("/db", GetDbHealth)
	return router
}

func GetAllHealth(w http.ResponseWriter, r *http.Request) {
	statusresponse := StatusResponse{
		Status:		true
		Message:	"All API healthchecks passed!"
	}
	render.JSON(w, r, statusresponse)
}

func GetApiHealth(w http.ResponseWriter, r *http.Request) {
        statusresponse := StatusResponse{
                Status:         true
                Message:        "API router healthcheck passed!"
        }
        render.JSON(w, r, statusresponse)
}

func GetDbHealth(w http.ResponseWriter, r *http.Request) {
        statusresponse := StatusResponse{
                Status:         true
                Message:        "Database healthcheck passed!"
        }
        render.JSON(w, r, statusresponse)
}



