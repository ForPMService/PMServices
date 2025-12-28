import { Component, inject, OnInit } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { OidcSecurityService } from 'angular-auth-oidc-client';
import { JsonPipe, AsyncPipe, NgIf } from '@angular/common';
import { map } from 'rxjs/operators'; // <-- Добавили map

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, JsonPipe, AsyncPipe, NgIf],
  templateUrl: './app.component.html',
  // Убрали styleUrl, так как файла может не быть. Если создадите scss - верните.
})
export class AppComponent implements OnInit {
  private readonly oidcSecurityService = inject(OidcSecurityService);

  isAuthenticated$ = this.oidcSecurityService.isAuthenticated$;

  // ИСПРАВЛЕНИЕ: Достаем userData из обертки
  userData$ = this.oidcSecurityService.userData$.pipe(
    map(result => result.userData) 
  );

  ngOnInit() {
    this.oidcSecurityService.checkAuth().subscribe(({ isAuthenticated, userData }) => {
      console.log('App authenticated:', isAuthenticated);
      if (isAuthenticated) {
        console.log('User data:', userData);
      }
    });
  }

  login() {
    this.oidcSecurityService.authorize();
  }

  logout() {
    this.oidcSecurityService.logoff().subscribe();
  }
}