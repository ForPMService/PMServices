using Npgsql;
namespace PMServices
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.

            builder.Services.AddControllers();
            // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();
            }

            app.UseHttpsRedirection();

            app.UseAuthorization();


            app.MapControllers();

            
            app.MapGet("/iam-ping", () => Results.Ok(new
            {
                Message = "PMServices IAM backend from Docker",
                Time = DateTime.UtcNow
            }));

            app.Run();
        }
    }
}
