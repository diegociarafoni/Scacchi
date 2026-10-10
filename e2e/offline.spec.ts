import { expect, test } from '@playwright/test';

test('il manifest rende l’app installabile', async ({ page, request }) => {
  await page.goto('/');
  const href = await page.locator('link[rel="manifest"]').getAttribute('href');
  expect(href).toBeTruthy();
  const response = await request.get(href ?? '');
  expect(response.ok()).toBe(true);
  const manifest = await response.json();
  expect(manifest.display).toBe('standalone');
  expect(manifest.icons.map((icon: { sizes: string }) => icon.sizes)).toEqual(
    expect.arrayContaining(['192x192', '512x512']),
  );
});

test('l’app si avvia senza rete dopo la prima visita', async ({ page, context }) => {
  await page.goto('/');
  await expect(page.locator('.board .square')).toHaveCount(64);

  // Attende che il service worker sia attivo e controlli la pagina.
  await page.evaluate(async () => {
    await navigator.serviceWorker.ready;
    if (!navigator.serviceWorker.controller) {
      await new Promise((resolve) =>
        navigator.serviceWorker.addEventListener('controllerchange', resolve, { once: true }),
      );
    }
  });

  await context.setOffline(true);
  await page.reload();

  await expect(page.locator('h1')).toHaveText('Scacchi');
  await expect(page.locator('.board .square')).toHaveCount(64);
  await expect(page.locator('[data-square="e1"]')).toHaveText('♔');
  await expect(page.locator('#status')).toHaveText('Offline');
});
